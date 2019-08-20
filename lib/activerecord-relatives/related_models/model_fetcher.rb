# frozen_string_literal: true

require 'activerecord-relatives/related_models/any_fetcher'
require 'activerecord-relatives/related_models/reflection_scope'

module ActiveRecord::Relatives
  class RelatedModels
    class ModelFetcher
      include AnyFetcher

      attr_reader :model

      def initialize(model, relations:)
        @model = model
        @relations = relations
      end

      def inspect
        "<#{self.class} model=#{model.name}, related=[#{target_models.map(&:name).join(', ')}]>"
      end

      def ids
        @ids ||= scope.pluck(model.primary_key).compact.uniq
      end

      def batch_scopes
        [scope]
      end

      def scope
        @scope ||= reflection_scopes.map(&:scope).reduce(:or)
      end

      def belongs_to_reflections
        model.reflections.values.select(&:belongs_to?).reject do |reflection|
          ActiveRecord::Relatives.config.ignorable_reflections[model]&.include?(reflection.name)
        end
      end

      private

      attr_reader :relations

      def reflection_scopes
        @reflection_scopes ||= belongs_to_reflections.map { |it| scopes_for_reflection(it) }.flatten
      end

      def target_models
        @target_models ||= belongs_to_reflections.map { |it| RelatedModels.target_models_for(it) }.uniq
      end

      def scopes_for_reflection(reflection)
        target_models = ActiveRecord::Relatives.config.target_models_for(reflection)
        target_models.map do |target_model|
          ReflectionScope.new(reflection, target_model: target_model, relations: relations)
        end
      end
    end
  end
end
