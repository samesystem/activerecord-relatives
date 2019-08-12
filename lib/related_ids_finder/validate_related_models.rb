# frozen_string_literal: true

module RelatedIdsFinder
  class ValidateRelatedModels
    include ApplicationInteractor

    context_attr :relation_ids

    def call
      context.warnings = []
      validate_missing_associations
      validate_collected_relations
    end

    private

    def validate_missing_associations
      (FindRelatedModels.active_record_models - relation_ids.keys).each do |missed_model|
        warn("Model was missed: #{missed_model}")
      end
    end

    def validate_collected_relations
      FindRelatedModels.dependencies.each do |model, dependency_data|
        dependency_data.each do |reflection_name, reflection_models|
          reflection = model.reflections[reflection_name]
          reflection_models.each do |reflection_model|
            ids = reflection_ids(reflection, reflection_model)
            extra_ids = ids - relation_ids[reflection_model]
            warn("#{model}:#{reflection_name}:#{reflection_model} has extra ids: #{extra_ids}") if extra_ids.present?
          end
        end
      end
    end

    def warn(warning)
      puts warning
      context.warnings << warning
    end

    def reflection_ids(reflection, reflection_model = nil)
      scope = model.unscoped
      scope = scope.where(reflection.foreign_type => reflection_model.name) if reflection.polymorphic?

      scope.pluck(reflection.foreign_key)
    end
  end
end
