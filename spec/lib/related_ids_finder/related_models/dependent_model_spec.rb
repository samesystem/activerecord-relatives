# frozen_string_literal: true

require 'rails_helper'

module RelatedIdsFinder
  class RelatedModels
    RSpec.describe DependentModel do
      subject(:dependent_model) { described_class.new(model) }

      let(:model) { Family }

      describe '#has_polymorphic_associations?' do
        context 'when model does not have polymorphic association' do
          it { is_expected.not_to be_with_polymorphic_associations }
        end

        context 'when model has at least one polymorphic association' do
          let(:model) { Message }

          it { is_expected.to be_with_polymorphic_associations }
        end
      end

      describe '#belongs_to_models' do
        subject(:belongs_to_models) { dependent_model.belongs_to_models }

        context 'when model associations are ignored via config' do
          it 'does not return ignored associations' do
            expect(belongs_to_models).to be_empty
          end
        end

        context 'when model does not have polymorphic association' do
          let(:model) { User }

          it 'returns models based on "belongs_to" associations' do
            expect(belongs_to_models).to match_array([Family])
          end
        end

        context 'when model has at least one polymorphic association' do
          let(:model) { Message }

          context 'when records with polymorphic associations exists' do
            before do
              create(:message, recipient: create(:family))
              create(:message, recipient: create(:note))
            end

            it 'returns associations based on polymorphic data in DB', :aggregate_failures do
              expect(belongs_to_models).to include(Family)
              expect(belongs_to_models).to include(Note)
            end
          end

          context 'when records with polymorphic associations does not exist' do
            it 'returns associations based on polymorphic data in DB', :aggregate_failures do
              expect(belongs_to_models).not_to include(Family)
              expect(belongs_to_models).not_to include(Note)
            end
          end
        end
      end
    end
  end
end
