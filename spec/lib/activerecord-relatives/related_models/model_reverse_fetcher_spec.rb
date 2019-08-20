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

      let(:user) { create(:user, avatar: image, family: family) }
      let(:family) { create(:family) }
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

      describe '#scope' do
        subject(:scope) { model_reverse_fetcher.scope }

        context 'when no relation points to root model' do
          let(:model_reverse_fetcher) do
            described_class.new(
              root_model: Image,
              relations: {}
            )
          end

          it 'returns empty scope' do
            expect(scope.to_sql).to be_blank
          end
        end

        context 'when multiple relations points to root model' do
          let(:model_reverse_fetcher) do
            described_class.new(
              root_model: Family,
              relations: {
                User => user_fetcher,
                Message => message_fetcher
              }
            )
          end

          let(:message_fetcher) { ModelForcedFetcher.new(Image, ids: [image.id]) }
          let!(:message) { create(:message, recipient: family) }

          it 'returns scope with multi subselects' do
            expect(scope.to_sql)
              .to match(%r{^SELECT "families".* FROM "families"})
              .and match(%r{IN \(SELECT "messages"."recipient_id"})
              .and match(%r{IN \(SELECT "messages"."recipient_id"})
          end
        end
      end
    end
  end
end
