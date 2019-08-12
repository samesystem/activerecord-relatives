# frozen_string_literal: true

require 'related_ids_finder/version'

module RelatedIdsFinder
  require_relative './related_ids_finder/find_related_models'
  require_relative './related_ids_finder/configuration'
  class Error < StandardError; end
  # Your code goes here...

  def self.call(scope_or_record)
    if scope_or_record.is_a?(ActiveRecord::Base)
      model = scope_or_record.class
      ids = [scope_or_record.id]
    else
      model = scope_or_record.klass
      ids = scope_or_record.pluck(:id)
    end

    FindRelatedModels.call(model: model, ids: ids)
  end

  def self.config
    @config ||= Configuration.new
    yield(@config) if block_given?
    @config
  end
end
