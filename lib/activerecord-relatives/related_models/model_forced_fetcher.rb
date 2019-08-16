# frozen_string_literal: true

require 'activerecord-relatives/related_models/any_fetcher'

module ActiveRecord::Relatives
  class RelatedModels
    class ModelForcedFetcher
      include AnyFetcher

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
