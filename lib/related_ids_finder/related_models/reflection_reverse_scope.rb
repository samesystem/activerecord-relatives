module RelatedIdsFinder
  class RelatedModels
    class ReflectionReverseScope
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
  end
end
