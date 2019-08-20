# frozen_string_literal: true

require 'spec_helper'

module ActiveRecord::Relatives
  class RelatedModels
    RSpec.describe AnyFetcher do
      subject(:fetcher) { fetcher_model.new }

      let(:fetcher_model) do
        Class.new do
          include AnyFetcher

          def count
            100
          end
        end
      end

      describe '#huge?' do
        let(:max_batch_ids_count) { 200 }

        before do
          ActiveRecord::Relatives.config.max_batch_ids_count = max_batch_ids_count
        end

        context 'when max_batch_ids_count is set to zero or below' do
          let(:max_batch_ids_count) { 0 }

          it { is_expected.to be_huge }
        end

        context 'when max_batch_ids_count is more then zero' do
          context 'when records count is less then max_batch_ids_count' do
            it { is_expected.not_to be_huge }
          end

          context 'when records count is more then given max_batch_ids_count' do
            let(:max_batch_ids_count) { 99 }

            it { is_expected.to be_huge }
          end
        end
      end
    end
  end
end
