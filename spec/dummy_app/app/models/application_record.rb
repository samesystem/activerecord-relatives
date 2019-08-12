# frozen_string_literal: true

# Set up model classes
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
