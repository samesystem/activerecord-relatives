# frozen_string_literal: true

require_relative './spec_helper'
require_relative './dummy_app/config/db_setup'
current_dir = File.expand_path(__dir__)
Dir["#{current_dir}/dummy_app/app/models/*.rb"].each { |path| require(path) }

require 'factory_bot'
require 'database_cleaner'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
    DatabaseCleaner.strategy = :transaction
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.before do
    RelatedIdsFinder.instance_variable_set(:@config, nil)
    RelatedIdsFinder.config.logger = nil
    RelatedIdsFinder.config.ignorable_reflections[User] = %i[mother father]
    RelatedIdsFinder.config.ignorable_reflections[Family] = %i[created_by]
  end
end
