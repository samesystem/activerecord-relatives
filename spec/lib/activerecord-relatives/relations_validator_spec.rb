# frozen_string_literal: true

require 'rails_helper'

module ActiveRecord::Relatives
  RSpec.describe RelationsValidator do
    subject(:validator) { described_class.new(relations) }
    let(:relations) { {} }

    describe '#validate' do
      subject(:validate) { validator.validate }

      let(:family) { create(:family, created_by: other_user) }
      let(:other_user) { create(:user, family: create(:family)) }
      let(:user) { create(:user, family: family) }

      let(:relations) do
        ActiveRecord::Relatives.call(family)
      end

      context 'when same object references multiple records of same model' do
        context 'when records are referenced via non-polymorphic association' do
          before do
            user.friends << other_user
          end

          it 'warns about out of bounds data' do
            validator.validate
            expect(validator.warnings.map(&:full_reflection_name)).to match_array(%w[UserFriend#friend])
          end
        end

        context 'when records are referenced via polymorphic association' do
          before do
            create(:message, recipient: other_user, author: user)
          end

          it 'warns about out of bounds data' do
            validator.validate
            expect(validator.warnings.map(&:full_reflection_name)).to match_array(%w[Message#recipient])
          end
        end
      end
    end
  end
end
