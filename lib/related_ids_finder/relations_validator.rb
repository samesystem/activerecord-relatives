# frozen_string_literal: true

module RelatedIdsFinder
  class RelationsValidator
    require 'related_ids_finder/relation_validator'
    attr_reader :warnings

    def initialize(relations)
      @relations = relations
      @warnings = []
    end

    def validate
      @warnings = []
      non_reverse_relations.each do |relation|
        @warnings += validate_relation(relation)
      end

      warnings.present?
    end

    def validate!
      non_reverse_relations.each { |relation| validate_relation!(relation) }
    end

    private

    attr_reader :relations

    def validate_relation(relation)
      RelationValidator.new(relation, other_relations: relations).tap(&:validate).warnings
    end

    def validate_relation!(relation)
      RelationValidator.new(relation, other_relations: relations).validate!
    end

    def non_reverse_relations
      relations.values.select do |relation|
        relation.is_a?(RelatedIdsFinder::RelatedModels::ModelFetcher)
      end
    end
  end
end
