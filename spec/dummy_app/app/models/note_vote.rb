# frozen_string_literal: true

require_relative './application_record'

class NoteVote < ApplicationRecord
  belongs_to :note
  belongs_to :user
end
