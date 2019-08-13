module RelatedIdsFinder
  class DependentHash
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
  end
end
