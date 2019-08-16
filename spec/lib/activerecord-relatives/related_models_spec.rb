# frozen_string_literal: true

require 'rails_helper'

module ActiveRecord::Relatives
  RSpec.describe RelatedModels do
    subject(:related_models) { described_class.new(model: Family, force_ids: [family.id]) }

    let(:family) { create(:family) }
    let(:user) { create(:user, family: family) }

    describe '#to_h' do
      subject(:to_h) { related_models.to_h }

      before do
        ActiveRecord::Relatives.config.logger = nil
        ActiveRecord::Relatives.config.ignorable_reflections[User] = %i[mother father]
        ActiveRecord::Relatives.config.ignorable_reflections[Family] = %i[created_by]
      end

      context 'when references to same model are defined' do
        before do
          # User#mother and User#father references to User class
          ActiveRecord::Relatives.config.ignorable_reflections[User] -= %i[mother father]
        end

        it 'raises exception' do
          expect { to_h }.to raise_error(ActiveRecord::Relatives::DependentHash::DependOnSelfError)
        end
      end

      context 'when circular references are present' do
        before do
          # Family#created_by points to user, but user has User#family reference
          ActiveRecord::Relatives.config.ignorable_reflections[Family] -= %i[created_by]
        end

        it 'raises exception' do
          expect { to_h }.to raise_error(ActiveRecord::Relatives::DependentHash::CircularDependencyError)
        end
      end

      context 'when multiple models have the same polymorphic association' do
        let(:message_author) { create(:user, family: create(:family)) }
        let!(:family_message) { create(:message, recipient: family, author: message_author) }
        let!(:user_message) { create(:message, recipient: user, author: message_author) }

        it 'collects all polymorphic references' do
          expect(to_h[Message].ids)
            .to match_array([family_message.id, user_message.id])
        end
      end

      context 'when model is reflected with has_one or has_many reflections only' do
        let(:image) { create(:image) }

        before { create(:user, family: family, avatar: image) }

        it 'collects reflected model ids' do
          expect(to_h[Image].ids).to match_array([image.id])
        end
      end

      context 'when model A has "belongs_to B" reflection' do
        context 'when model B has only polymorphic reflections' do
          let(:model_a) { NoteVote }
          let(:model_b) { Note }

          context 'when model B has records' do
            let!(:record_a) { create(:note_vote, note: record_b) }
            let!(:record_b) { create(:note, notable: family) }

            it 'includes model A records' do
              expect(to_h[model_a].ids).to eq([record_a.id])
            end

            it 'includes model b records' do
              expect(to_h[model_b].ids).to eq([record_b.id])
            end
          end

          context 'when model B has no polymorphic records' do
            let!(:record_a) { create(:note_vote, user: user) }

            it 'includes model A records' do
              expect(to_h[model_a].ids).to eq([record_a.id])
            end

            it 'includes model b without records' do
              expect(to_h[model_b].ids).to be_empty
            end
          end
        end
      end
    end
  end
end
