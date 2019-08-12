# frozen_string_literal: true

require_relative './application_record'

class User < ApplicationRecord
  belongs_to :family
  belongs_to :father, class_name: 'User'
  belongs_to :mother, class_name: 'User'
  belongs_to :avatar, class_name: 'Image'

  has_many :messages, as: :recipient
end
