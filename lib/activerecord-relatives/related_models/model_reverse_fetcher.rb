# frozen_string_literal: true

require 'activerecord-relatives/related_models/any_fetcher'
require 'activerecord-relatives/related_models/reflection_reverse_scope'

module ActiveRecord::Relatives
  class RelatedModels
    class ModelReverseFetcher
      include AnyFetcher

      def self.child_reflections_for(root_model)
        ActiveRecord::Relatives.config.active_record_models.flat_map do |child|
          child.reflections.values.select(&:belongs_to?).select do |reflection|
            targets = ActiveRecord::Relatives.config.target_models_for(reflection, include_reverse: true)
            targets.include?(root_model)
          end
        end
      end

      def initialize(root_model:, relations:)
        @root_model = root_model
        @relations = relations
      end

      def ids
        @ids ||= scope.pluck(root_model.primary_key)
      end

      def scope
        @scope ||= begin
          initial_scope = root_model.unscoped
          child_scopes
            .map { |child_scope| initial_scope.where(root_model.primary_key => child_scope) }
            .reduce(:or)
        end
      end

      private

      attr_reader :root_model, :relations

      def child_scopes
        child_reflections.map do |reflection|
          reflection_scope(reflection)&.scope&.select(reflection.foreign_key)
        end.compact
      end

      def reflection_scope(reflection)
        return unless relations.key?(reflection.active_record)

        ReflectionReverseScope.new(
          reflection,
          child_relation: relations.fetch(reflection.active_record),
          root_model: root_model
        )
      end

      def child_reflections
        @child_reflections ||= self.class.child_reflections_for(root_model)
      end
    end
  end
end
