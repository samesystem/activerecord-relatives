# frozen_string_literal: true

require 'rails_helper'

module ActiveRecord::Relatives
  class RelatedModels
    RSpec.describe ModelFetcher do
      subject(:model_fetcher) { described_class.new(root_model, relations: relations) }

      let(:root_model) { User }
      let(:relations) do
        {
          Family => family_fetcher,
          Message => message_fetcher
        }
      end

      let(:family_fetcher) { ModelForcedFetcher.new(Family, ids: family_ids) }
      let(:message_fetcher) { ModelForcedFetcher.new(Message, ids: [1, 2, 3]) }
      let(:families) { create_pair(:family) }
      let(:family_ids) { families.map(&:id) }

      before do
      end

      describe '#scope' do
        context 'when model has relation with small ids count' do
          it 'generates scope with relation ids' do
            expect(model_fetcher.scope.to_sql).to include("\"users\".\"family_id\" IN (#{family_ids.join(', ')})")
          end
        end

        context 'when model has relations with very large ids count' do
          before do
            allow(family_fetcher).to receive(:huge?).and_return(true)
          end

          it 'generates scope with relation ids' do
            expect(model_fetcher.scope.to_sql)
              .to include('"users"."family_id" IN (SELECT "families"."id" FROM "families"')
          end
        end
      end
    end
  end
end
