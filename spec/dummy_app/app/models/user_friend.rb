# frozen_string_literal: true

require_relative './application_record'

class UserFriend < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: 'User'

  has_many :messages, as: :recipient
end
