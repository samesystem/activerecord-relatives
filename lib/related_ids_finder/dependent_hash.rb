# frozen_string_literal: true

module RelatedIdsFinder
  class DependentHash
    DependencyError = Class.new(StandardError)
    DependOnSelfError = Class.new(DependencyError)
    CircularDependencyError = Class.new(DependencyError)

    class Dependency
      attr_reader :key, :depends_on

      def initialize(key:, block:, depends_on:)
        @block = block
        @depends_on = []
        @key = key
        add_dependencies(depends_on)
      end

      def free?
        @depends_on.empty?
      end

      def add_dependencies(dependent_keys)
        raise DependOnSelfError, "#{key} can not depend on it self" if dependent_keys.include?(key)

        @depends_on = (@depends_on + dependent_keys).uniq
      end

      def depends_on?(*keys)
        (keys - depends_on).empty?
      end

      def remove_dependencies(dependent_keys)
        @depends_on -= dependent_keys
      end

      def inspect
        [
          key.to_s,
          "[#{[depends_on].map(&:to_s).map(&:inspect).join(' + ')}]"
        ].select(&:present?).join(' : ')
      end

      def run(data)
        block.call(data)
      end

      private

      attr_reader :block
    end

    attr_reader :dependencies

    def initialize
      @dependencies = []
    end

    def key?(key)
      dependencies.any? { |it| it.key == key }
    end

    def set(key, depends_on: [], &block)
      dependency = build_dependency(key, depends_on: depends_on, &block)

      related_dependencies(key).each do |related|
        include_dependencies_for(related, copy_from: dependency)
      end
      @dependencies << dependency
    end

    def result
      @result ||= begin
        validate
        result_from_free_dependencies
      end
    end

    def unsatisfied_dependencies
      depends_on = dependencies.flat_map(&:depends_on).uniq
      depends_on - dependencies.map(&:key)
    end

    private

    def related_dependencies(key)
      dependencies.select { |it| it.depends_on?(key) }
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
      raise DependencyError, "trying to add same key twice #{key}" if dependencies.map(&:key).include?(key)

      Dependency.new(key: key, block: block, depends_on: depends_on)
    end

    def validate
      if unsatisfied_dependencies.any?
        unsatisfied_dependency = unsatisfied_dependencies.first
        sample_dependency = dependencies.detect { |d| d.depends_on.include?(unsatisfied_dependency) }
        raise "Some dependencies can not be satisfied: #{sample_dependency.key} depends on #{unsatisfied_dependency}"
      end
    end

    def result_from_free_dependencies(not_triggered_dependencies = dependencies.dup.map(&:dup), result: {})
      free_dependencies, not_free_dependencies = not_triggered_dependencies.partition(&:free?)

      return result if free_dependencies.empty?

      free_dependencies.each do |dependency|
        raise DependencyError, "Updating same dependency twice #{dependency.key}" if result.key?(dependency.key)

        result[dependency.key] = dependency.run(result)
      end

      not_free_dependencies.each { |it| it.remove_dependencies(result.keys) }
      result_from_free_dependencies(not_free_dependencies, result: result)
    end
  end
end
