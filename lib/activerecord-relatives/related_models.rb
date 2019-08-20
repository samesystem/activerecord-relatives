# frozen_string_literal: true

module ActiveRecord::Relatives
  class RelatedModels
    require 'active_support'
    require 'activerecord-relatives/related_models/model_fetcher'
    require 'activerecord-relatives/related_models/model_forced_fetcher'
    require 'activerecord-relatives/related_models/model_reverse_fetcher'
    require 'activerecord-relatives/related_models/dependent_model'
    require 'activerecord-relatives/dependent_hash'

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
        new_object.dependency_resolver.before_dependency_resolve do |data|
          new_relation = data[:partial_result]
          old_relations = data[:old_result]
          RelationValidator.new(new_relation, other_relations: old_relations).validate
        end
      end
    end

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

    def validate!
      RelationsValidator.new(to_h).validate!
    end

    private

    attr_reader :force_ids, :model

    def config
      ActiveRecord::Relatives.config
    end

    def hidden_models(dependency_resolver)
      active_record_models - empty_polymorphic_models - dependency_resolver.keys
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

    def setup_dependency_resolver(root_model:, force_ids: nil, dependency_resolver:)
      root_dependent_model = DependentModel.new(root_model)

      dependency_resolver.set(root_model, depends_on: root_dependent_model.belongs_to_models) do |relations|
        if force_ids
          ModelForcedFetcher.new(root_model, ids: force_ids)
        else
          ModelFetcher.new(root_model, relations: relations)
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

        ModelReverseFetcher.new(
          root_model: root_model,
          relations: relations
        )
      end

      dependency_resolver
    end
  end
end
