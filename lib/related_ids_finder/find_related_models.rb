# frozen_string_literal: true

module RelatedIdsFinder
  class FindRelatedModels
    require 'active_support'
    require 'related_ids_finder/find_related_models/model_fetcher'
    require 'related_ids_finder/find_related_models/model_forced_fetcher'
    require 'related_ids_finder/find_related_models/model_reverse_fetcher'
    require 'related_ids_finder/find_related_models/dependent_model'
    require 'related_ids_finder/dependent_hash'

    def self.call(*args)
      new(*args).call
    end

    def initialize(model:, force_ids: nil)
      @model = model
      @force_ids = force_ids
    end

    def call
      waiter = setup_waiter(root_model: model, force_ids: force_ids, waiter: DependentHash.new)

      hidden_models(waiter).each do |reverse_model|
        waiter = setup_reverse_waiter(root_model: reverse_model, waiter: waiter)
      end

      waiter
    end

    private

    attr_reader :force_ids, :model

    def config
      RelatedIdsFinder.config
    end

    def hidden_models(waiter)
      active_record_models - waiter.dependencies.map(&:key)
    end

    def active_record_models
      config.active_record_models
    end

    def inform(message)
      config.logger&.info("#{Time.current.strftime('%H:%M:%S')} | #{message}")
    end

    def setup_waiter(root_model:, force_ids: nil, waiter:)
      root_dependent_model = DependentModel.new(root_model)

      waiter.set(root_model, depends_on: root_dependent_model.belongs_to_models) do |relations|
        ids_count = relations.values_at(*root_dependent_model.belongs_to_models).compact.flat_map(&:ids).count
        inform("-- fetching #{root_model} (depends by #{ids_count} ids on [#{root_dependent_model.belongs_to_models.join(' -> ')}])")

        if force_ids
          ModelForcedFetcher.new(root_model, ids: force_ids).tap(&:ids)
        else
          ModelFetcher.new(root_model, relations: relations).tap(&:ids)
        end
      end

      root_dependent_model.child_models.each do |model|
        next if waiter.key?(model)

        setup_waiter(root_model: model, waiter: waiter)
      end

      waiter
    end

    def setup_reverse_waiter(root_model:, waiter:)
      child_models = ModelReverseFetcher.child_reflections_for(root_model).map(&:active_record)

      waiter.set(root_model, depends_on: child_models) do |relations|
        ids_count = relations.values_at(*child_models).compact.map(&:ids).flatten.count
        inform("-- reverse fetching #{root_model} (depends by #{ids_count} ids on #{child_models.join(' -> ')})")

        ModelReverseFetcher.new(
          root_model: root_model,
          relations: relations
        ).tap(&:ids)
      end

      waiter
    end
  end
end
