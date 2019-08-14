# frozen_string_literal: true

require_relative './application_record'

# Dummy model for testing polymorphic-only dependencies cases
class Note < ApplicationRecord
  belongs_to :notable, polymorphic: true
  # DO NOT ADD MORE ASSOCIATIONS
end
