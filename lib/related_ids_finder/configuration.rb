# frozen_string_literal: true

module RelatedIdsFinder
  class Configuration
    STDOUT_LOGGER = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
    NOT_DEFINED = Object.new.freeze

    attr_accessor(
      :ignorable_reflections, :model_filter, :default_polymorphic_models,
      :max_batch_ids_count, :logger
    )

    def initialize
      self.ignorable_reflections = {}
      self.model_filter = ->(_model) { true }
      self.default_polymorphic_models = {}
      self.max_batch_ids_count = 10_000
      self.logger = STDOUT_LOGGER
    end

    def active_record_models
      @active_record_models ||= \
        ActiveRecord::Base
        .descendants
        .select { |model| allowed_model?(model) }
        .uniq.sort_by(&:name)
    end

    def target_models_for(reflection, include_reverse: false)
      model = reflection.active_record

      return [] if ignorable_reflections.dig(model)&.include?(reflection.name)

      @target_models_for ||= RelatedIdsFinder.config.default_polymorphic_models.dup
      @target_models_for[model] ||= {}
      @target_models_for[model][reflection.name.to_sym] ||= fetch_target_models(reflection)
      target_models = @target_models_for[model][reflection.name.to_sym]
      include_reverse ? target_models : (target_models - reverse_reflection_models)
    end

    def reverse_reflection_models
      @reverse_reflection_models ||= active_record_models.select { |model| model.reflections.values.select(&:belongs_to?).empty? }
    end

    private

    def allowed_model?(model)
      model_filter.call(model)
    end

    def fetch_target_models(reflection)
      fetch_all_target_models(reflection).select do |target_model|
        allowed_model?(target_model)
      end
    end

    def fetch_all_target_models(reflection)
      model = reflection.active_record

      if reflection.polymorphic?
        column_name = reflection.foreign_type
        model.distinct.pluck(column_name).compact.map(&:constantize)
      else
        [reflection.klass]
      end
    end
  end
end
