# frozen_string_literal: true

module ActiveRecord::Relatives
  class DependentHash
    require 'active_support'
    require_relative './dependent_hash/dependency'

    DependencyError = Class.new(StandardError)
    DependOnSelfError = Class.new(DependencyError)
    CircularDependencyError = Class.new(DependencyError)

    attr_reader :dependencies

    delegate :values, :[], to: :result
    delegate :keys, :key?, to: :dependencies

    def initialize
      @dependencies = {}
    end

    def dependency(key)
      dependencies[key]
    end

    def set(key, depends_on: [], &block)
      dependency = build_dependency(key, depends_on: depends_on, &block)

      related_dependencies(key).values.each do |related|
        include_dependencies_for(related, copy_from: dependency)
      end
      dependencies[key] = dependency
    end

    def before_dependency_resolve(&block)
      @before_dependency_resolve ||= []
      @before_dependency_resolve << block if block_given?
      @before_dependency_resolve
    end

    def result
      @result ||= begin
        validate
        result_from_free_dependencies
      end
    end

    def unsatisfied_dependencies
      depends_on = dependencies.values.flat_map(&:depends_on).uniq
      depends_on - dependencies.keys
    end

    private

    def related_dependencies(key)
      dependencies.select { |_, dependency| dependency.depends_on?(key) }
    end

    def include_dependencies_for(dependency, copy_from:)
      dependency.add_dependencies(copy_from.depends_on)
    rescue DependOnSelfError
      error_message = \
        "Circular dependency #{copy_from.key}:#{copy_from.depends_on.map(&:to_s)}, " \
        "but #{dependency.key}:#{dependency.depends_on.map(&:to_s)}"
      raise CircularDependencyError, error_message
    end

    def build_dependency(key, depends_on:, &block)
      raise DependencyError, "trying to add same key twice #{key}" if dependencies.key?(key)

      Dependency.new(key: key, block: block, depends_on: depends_on)
    end

    def validate
      return if unsatisfied_dependencies.empty?

      unsatisfied_dependency = unsatisfied_dependencies.first
      sample_dependency = dependencies.values.detect { |d| d.depends_on.include?(unsatisfied_dependency) }
      raise "Some dependencies can not be satisfied: #{sample_dependency.key} depends on #{unsatisfied_dependency}"
    end

    def result_from_free_dependencies(not_triggered_dependencies = dependencies.values.map(&:dup), result: {})
      free_dependencies, not_free_dependencies = not_triggered_dependencies.partition(&:free?)

      return result if free_dependencies.empty?

      free_dependencies.each do |dependency|
        raise DependencyError, "Updating same dependency twice #{dependency.key}" if result.key?(dependency.key)

        result[dependency.key] = resolve_dependency(dependency, result: result)
      end

      not_free_dependencies.each { |it| it.remove_dependencies(result.keys) }
      result_from_free_dependencies(not_free_dependencies, result: result)
    end

    def resolve_dependency(dependency, result:)
      dependency.run(result).tap do |updated_result|
        before_dependency_resolve.each do |block|
          data = { dependency: dependency, partial_result: updated_result, old_result: result }
          block.call(data)
        end
      end
    end
  end
end
