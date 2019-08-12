# frozen_string_literal: true

require_relative './application_record'

class Message < ApplicationRecord
  belongs_to :recipient, polymorphic: true
  belongs_to :author, class_name: 'User'
  belongs_to :image
end
