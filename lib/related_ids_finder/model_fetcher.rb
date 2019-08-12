# frozen_string_literal: true

require 'related_ids_finder/any_fetcher'
require 'related_ids_finder/reflection_scope'

module RelatedIdsFinder
  class ModelFetcher
    include AnyFetcher

    def initialize(model, relations:)
      @model = model
      @relations = relations
    end

    def inspect
      "<#{self.class} model=#{model.name}, related=[#{target_models.map(&:name).join(', ')}]>"
    end

    def ids
      @ids ||= begin
        batch_scopes.map { |batch_scope| batch_scope.pluck(:id) }.flatten.compact.uniq
      end
    end

    def batch_scopes
      [scope]
    end

    def scope
      @scope ||= reflection_scopes.map(&:scope).reduce(:or)
    end

    private

    attr_reader :model, :relations

    def reflection_scopes
      @reflection_scopes ||= belongs_to_reflections.map { |it| scopes_for_reflection(it) }.flatten
    end

    def belongs_to_reflections
      model.reflections.values.select(&:belongs_to?).reject do |reflection|
        RelatedIdsFinder.config.ignorable_reflections[model]&.include?(reflection.name)
      end
    end

    def target_models
      @target_models ||= belongs_to_reflections.map { |it| FindRelatedModels.target_models_for(it) }.uniq
    end

    def scopes_for_reflection(reflection)
      target_models = RelatedIdsFinder.config.target_models_for(reflection)
      target_models.map do |target_model|
        ReflectionScope.new(reflection, target_model: target_model, relations: relations)
      end
    end
  end
end
