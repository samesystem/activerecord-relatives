# frozen_string_literal: true

# Instead of loading all of Rails, load the
# particular Rails dependencies we need
require 'sqlite3'
require 'active_record'

# Set up a database that resides in RAM
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Set up database tables and columns
ActiveRecord::Schema.define do
  create_table :schema_migrations, force: true do |t|
    t.string :version, index: true
  end

  create_table :users, force: true do |t|
    t.string :name
    t.integer :family_id, index: true
    t.integer :avatar_id, index: true
  end

  create_table :user_friends, force: true do |t|
    t.integer :user_id, index: true
    t.integer :friend_id, index: true
  end

  create_table :families, force: true do |t|
    t.string :name

    t.integer :logo_id, index: true
    t.integer :created_by_id, index: true
  end

  create_table :messages, force: true do |t|
    t.string :content
    t.string :recipient_type
    t.integer :recipient_id, index: true

    t.integer :image_id, index: true
    t.integer :author_id, index: true
  end

  create_table :note_votes, force: true do |t|
    t.integer :stars_count
    t.integer :user_id, index: true
    t.integer :note_id, index: true
  end

  create_table :notes, force: true do |t|
    t.string :content
    t.integer :notable_id, index: true
    t.string :notable_type
  end

  create_table :images, force: true do |t|
    t.string :url
  end

  create_table :pets, force: true do |t|
    t.string :name
    t.references :owner
  end
end
