# frozen_string_literal: true

module RelatedIdsFinder
  class RelatedModels
    class DependentModel
      attr_reader :model

      def initialize(model)
        @model = model
      end

      def with_polymorphic_associations?
        model.reflections.values.any? { |it| it.belongs_to? && it.polymorphic? }
      end

      def child_models
        all_models.select do |child_model|
          child_model.belongs_to_models.include?(model)
        end.map(&:model)
      end

      def belongs_to_models
        @belongs_to_models ||= model.reflections.values.select(&:belongs_to?).flat_map do |reflection|
          RelatedIdsFinder.config.target_models_for(reflection)
        end.uniq
      end

      private

      def all_models
        @all_models ||= RelatedIdsFinder.config.active_record_models.map { |it| self.class.new(it) }
      end
    end
  end
end
