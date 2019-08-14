# frozen_string_literal: true

module RelatedIdsFinder
  class RelatedModels
    class ReflectionScope
      def initialize(reflection, relations:, target_model:)
        @reflection = reflection
        @model = reflection.active_record
        @target_model = target_model
        @relations = relations
      end

      def scope
        if depends_on_many_ids?
          initial_scope.where(reflection.foreign_key => target_scope)
        else
          initial_scope.where(reflection.foreign_key => target_ids)
        end
      end

      def depends_on_many_ids?
        relations.fetch(target_model).huge?
      end

      private

      attr_reader :model, :relations, :reflection, :target_model

      def target_ids
        relations.fetch(target_model).ids
      end

      def target_scope
        relations.fetch(target_model).scope
      end

      def initial_scope
        scope = model.unscoped
        return scope unless reflection.polymorphic?

        scope.where(reflection.foreign_type => target_model.name)
      end
    end
  end
end
