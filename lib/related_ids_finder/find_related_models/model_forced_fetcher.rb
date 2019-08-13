# frozen_string_literal: true

require 'related_ids_finder/find_related_models/any_fetcher'

module RelatedIdsFinder
  class FindRelatedModels
    class ModelForcedFetcher
      attr_reader :ids

      def initialize(root_model, ids:)
        @ids = ids
        @root_model = root_model
      end

      def inspect
        "<#{self.class} model=#{root_model}]>"
      end

      def scope
        root_model.unscoped.where(root_model.primary_key => ids)
      end

      def huge?
        false
      end

      private

      attr_reader :root_model
    end
  end
end
