# frozen_string_literal: true

module ActiveRecord
  module Relatives
    require 'activerecord-relatives/version'
    require_relative './activerecord-relatives/related_models'
    require_relative './activerecord-relatives/configuration'
    require_relative './activerecord-relatives/relations_validator'
    class Error < StandardError; end
    # Your code goes here...

    def self.dependency_resolver(scope_or_record)
    end

    def self.call(scope_or_record)
      if scope_or_record.is_a?(ActiveRecord::Base)
        model = scope_or_record.class
        ids = [scope_or_record.id]
      else
        model = scope_or_record.klass
        ids = scope_or_record.pluck(:id)
      end

      RelatedModels.new(model: model, force_ids: ids)
    end

    def self.config
      @config ||= Configuration.new
      yield(@config) if block_given?
      @config
    end
  end
end
