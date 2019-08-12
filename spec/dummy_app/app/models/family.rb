# frozen_string_literal: true

require_relative './application_record'

class Family < ApplicationRecord
  has_many :users
  has_many :messages, as: :recipient

  belongs_to :created_by, class_name: 'User'
  belongs_to :logo, class_name: 'Image'
end
