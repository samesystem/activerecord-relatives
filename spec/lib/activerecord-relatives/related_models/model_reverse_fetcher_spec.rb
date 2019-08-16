# frozen_string_literal: true

require 'rails_helper'

module ActiveRecord::Relatives
  class RelatedModels
    RSpec.describe ModelReverseFetcher do
      subject(:model_reverse_fetcher) do
        described_class.new(
          root_model: Image,
          relations: { User => user_fetcher }
        )
      end

      let(:user) { create(:user, avatar: image) }
      let(:image) { create(:image) }
      let(:user_fetcher) { ModelForcedFetcher.new(User, ids: [user.id]) }

      describe '#ids' do
        subject(:ids) { model_reverse_fetcher.ids }

        before do
          create(:image)
        end

        context 'when related data has small amount of ids' do
          it 'returns correct root model ids' do
            expect(ids).to match_array([image.id])
          end
        end

        context 'when related data has big amount of ids' do
          before do
            allow(user_fetcher).to receive(:huge?).and_return(true)
          end

          it 'returns correct root model ids' do
            expect(ids).to match_array([image.id])
          end
        end
      end
    end
  end
end
