# frozen_string_literal: true

require 'related_ids_finder/any_fetcher'

module RelatedIdsFinder
  class ModelReverseFetcher
    class ReverseReflectionScope
      def initialize(reflection, child_relation:)
        @child_relation = child_relation
        @reflection = reflection
      end

      def ids
        @ids ||= scope.distinct.pluck(reflection.foreign_key).compact
      end

      def inspect
        "<#{self.class} model=#{child_model}]>"
      end

      def scope
        @scope ||=
          if child_relation.huge?
            initial_scope.where(child_model.primary_key => child_relation.scope)
          else
            initial_scope.where(child_model.primary_key => child_relation.ids)
          end
      end

      private

      attr_reader :reflection, :child_relation

      def child_model
        reflection.active_record
      end

      def initial_scope
        scope = child_model.unscoped
        return scope unless reflection.polymorphic?

        scope.where(reflection.foreign_type => root_model.name)
      end
    end

    def self.child_reflections_for(root_model)
      RelatedIdsFinder.config.active_record_models.flat_map do |child|
        child.reflections.values.select(&:belongs_to?).select do |reflection|
          targets = RelatedIdsFinder.config.target_models_for(reflection, include_reverse: true)
          targets.include?(root_model)
        end
      end
    end

    def initialize(root_model:, relations:)
      @root_model = root_model
      @relations = relations
    end

    def ids
      @ids ||= child_reflections
               .map { |it| reflection_scope(it) }
               .compact
               .flat_map(&:ids)
    end

    def scope
      child_reflections.map { |it| reflection_scope(it) }.compact.map(&:scope).reduce(:or)
    end

    private

    attr_reader :root_model, :relations

    def reflection_scope(reflection)
      return unless relations.key?(reflection.active_record)

      ReverseReflectionScope.new(reflection, child_relation: relations.fetch(reflection.active_record))
    end

    def child_reflections
      @child_reflections ||= self.class.child_reflections_for(root_model)
    end
  end
end
