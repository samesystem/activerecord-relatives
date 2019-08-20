# frozen_string_literal: true

module ActiveRecord::Relatives
  class RelatedModels
    module AnyFetcher
      def ids
        @ids ||= scope.pluck(model.primary_key).compact.uniq
      end

      def huge?
        ActiveRecord::Relatives.config.max_batch_ids_count <= 0 ||
          count > ActiveRecord::Relatives.config.max_batch_ids_count
      end

      def count
        @count ||= @ids&.count || scope.count
      end

      def scope
        raise NotImplementedError
      end
    end
  end
end
