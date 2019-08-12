# frozen_string_literal: true

module RelatedIdsFinder
  module AnyFetcher
    def ids
      raise NotImplementedError
    end

    def huge?
      ids.count > RelatedIdsFinder.config.max_batch_ids_count
    end

    def scope
      raise NotImplementedError
    end
  end
end
