# frozen_string_literal: true

module ActiveRecord::Relatives
  class RelationValidator
    RelationValidationError = Class.new(StandardError)

    require 'activerecord-relatives/relation_validator/out_of_scope_warning'
    attr_reader :warnings

    def initialize(relation, other_relations:)
      @relation = relation
      @relations = other_relations
      @warnings = []
    end

    def validate!
      validate
      raise RelationValidationError, warnings.first.message if warnings.any?
    end

    def validate
      @warnings = []
      return true unless validatable?

      @warnings += validate_relation
      warnings.present?
    end

    private

    attr_reader :relations, :relation

    def validatable?
      relation.is_a?(ActiveRecord::Relatives::RelatedModels::ModelFetcher)
    end

    def validate_relation
      relation.belongs_to_reflections.flat_map do |reflection|
        validate_reflection(reflection)
      end.compact
    end

    def validate_reflection(reflection)
      ActiveRecord::Relatives.config.target_models_for(reflection).map do |target|
        scope = relation.scope
        scope = scope.where(reflection.foreign_type => target.name) if reflection.polymorphic?
        validate_reflection_scope(reflection, scope: scope, target: target)
      end.compact
    end

    def validate_reflection_scope(reflection, scope:, target:)
      foreign_key = reflection.foreign_key
      ids = scope.where.not(foreign_key => nil).distinct.pluck(foreign_key)
      reflection_target = target
      extra_ids = ids - relations[target].ids

      return if extra_ids.empty?

      OutOfScopeWarning.new(extra_ids: extra_ids, reflection: reflection, reflection_target: reflection_target)
    end
  end
end
