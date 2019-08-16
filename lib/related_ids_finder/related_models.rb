# frozen_string_literal: true

module RelatedIdsFinder
  class RelatedModels
    require 'active_support'
    require 'related_ids_finder/related_models/model_fetcher'
    require 'related_ids_finder/related_models/model_forced_fetcher'
    require 'related_ids_finder/related_models/model_reverse_fetcher'
    require 'related_ids_finder/related_models/dependent_model'
    require 'related_ids_finder/dependent_hash'

    delegate :[], :transform_values, :transform_keys, :values, to: :to_h

    def initialize(model:, force_ids: nil)
      @model = model
      @force_ids = force_ids
    end

    def initialize_copy(other)
      super
      @dependency_resolver = other.instance_variable_get(:@dependency_resolver)&.dup
    end

    def to_h
      @to_h ||= dependency_resolver.result
    end

    def with_validations
      dup.tap do |new_object|
        new_object.send(:dependency_resolver).before_dependency_resolve do |updates, result|
          p "validating #{updates.keys}"
          RelationValidator.new(updates.values.first, other_relations: result).validate
        end
      end
    end

    def validate!
      RelationsValidator.new(to_h).validate!
    end

    private

    attr_reader :force_ids, :model

    def dependency_resolver
      @dependency_resolver ||= begin
        resolver = DependentHash.new
        resolver = \
          setup_dependency_resolver(root_model: model, force_ids: force_ids, dependency_resolver: resolver)

        (empty_polymorphic_models - [model]).each do |empty_model|
          resolver = \
            setup_dependency_resolver(root_model: empty_model, force_ids: [], dependency_resolver: resolver)
        end

        hidden_models(resolver).each do |reverse_model|
          resolver = \
            setup_reverse_dependency_resolver(root_model: reverse_model, dependency_resolver: resolver)
        end

        resolver
      end
    end

    def config
      RelatedIdsFinder.config
    end

    def hidden_models(dependency_resolver)
      missed_models = active_record_models - empty_polymorphic_models - dependency_resolver.dependencies.map(&:key)
    end

    def empty_polymorphic_models
      active_record_models
        .map { |model| DependentModel.new(model) }
        .select { |model| model.with_polymorphic_associations? && model.belongs_to_models.empty? }
        .map { |dependent_model| dependent_model.model }
    end

    def active_record_models
      config.active_record_models
    end

    def inform(message)
      config.logger&.info("#{Time.current.strftime('%H:%M:%S')} | #{message}")
    end

    def setup_dependency_resolver(root_model:, force_ids: nil, dependency_resolver:)
      root_dependent_model = DependentModel.new(root_model)

      dependency_resolver.set(root_model, depends_on: root_dependent_model.belongs_to_models) do |relations|
        ids_count = relations.values_at(*root_dependent_model.belongs_to_models).compact.flat_map(&:ids).count
        inform("-- fetching #{root_model} (depends by #{ids_count} ids on [#{root_dependent_model.belongs_to_models.join(' -> ')}])")

        if force_ids
          ModelForcedFetcher.new(root_model, ids: force_ids).tap(&:ids)
        else
          ModelFetcher.new(root_model, relations: relations).tap(&:ids)
        end
      end

      root_dependent_model.child_models.each do |model|
        next if dependency_resolver.key?(model)

        setup_dependency_resolver(root_model: model, dependency_resolver: dependency_resolver)
      end

      dependency_resolver
    end

    def setup_reverse_dependency_resolver(root_model:, dependency_resolver:)
      child_models = ModelReverseFetcher.child_reflections_for(root_model).map(&:active_record)

      dependency_resolver.set(root_model, depends_on: child_models) do |relations|
        ids_count = relations.values_at(*child_models).compact.map(&:ids).flatten.count
        inform("-- reverse fetching #{root_model} (depends by #{ids_count} ids on #{child_models.join(' -> ')})")

        ModelReverseFetcher.new(
          root_model: root_model,
          relations: relations
        ).tap(&:ids)
      end

      dependency_resolver
    end
  end
end
