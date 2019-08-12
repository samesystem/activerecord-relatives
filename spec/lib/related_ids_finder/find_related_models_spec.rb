# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RelatedIdsFinder::FindRelatedModels do
  subject(:find_related_models) { described_class.new(model: Family, force_ids: [family.id]) }

  let(:family) { create(:family) }
  let(:user) { create(:user, family: family) }
  let(:pet) { create(:pet, family: family, user: user) }

  describe '#call' do
    subject(:call) { find_related_models.call }

    before do
      RelatedIdsFinder.config.logger = nil
      RelatedIdsFinder.config.ignorable_reflections[User] = %i[mother father]
      RelatedIdsFinder.config.ignorable_reflections[Family] = %i[created_by]
    end

    context 'when references to same model are defined' do
      before do
        # User#mother and User#father references to User class
        RelatedIdsFinder.config.ignorable_reflections[User] -= %i[mother father]
      end

      it 'raises exception' do
        expect { call }.to raise_error(RelatedIdsFinder::DependentHash::DependOnSelfError)
      end
    end

    context 'when circular references are present' do
      before do
        # Family#created_by points to user, but user has User#family reference
        RelatedIdsFinder.config.ignorable_reflections[Family] -= %i[created_by]
      end

      it 'raises exception' do
        expect { call }.to raise_error(RelatedIdsFinder::DependentHash::CircularDependencyError)
      end
    end

    context 'when multiple models have the same polymorphic association' do
      let(:message_author) { create(:user, family: create(:family)) }
      let!(:family_message) { create(:message, recipient: family, author: message_author) }
      let!(:user_message) { create(:message, recipient: user, author: message_author) }

      it 'collects all polymorphic references' do
        expect(call.result[Message].ids)
          .to match_array([family_message.id, user_message.id])
      end
    end

    context 'when model is reflected with has_one or has_many reflections only' do
      let(:image) { create(:image) }

      before { create(:user, family: family, avatar: image) }

      it 'collects reflected model ids' do
        expect(call.result[Image].ids).to match_array([image.id])
      end
    end
  end
end
