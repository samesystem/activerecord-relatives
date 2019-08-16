# frozen_string_literal: true

module ActiveRecord::Relatives
  class RelatedModels
    module AnyFetcher
      def ids
        raise NotImplementedError
      end

      def huge?
        ids.count > ActiveRecord::Relatives.config.max_batch_ids_count
      end

      def scope
        raise NotImplementedError
      end
    end
  end
end
