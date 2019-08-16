# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActiveRecord::Relatives do
  it 'has a version number' do
    expect(ActiveRecord::Relatives::VERSION).not_to be nil
  end

  describe '.call' do
    subject(:call) { described_class.call(record_or_relation) }

    let(:record_or_relation) { family }
    let(:family) { create(:family) }
    let!(:user) { create(:user, family: family) }

    context 'when record is given' do
      it 'returns related ids' do
        related_ids = call.transform_values(&:ids).select { |_, val| val.present? }

        expect(related_ids).to eq(
          Family => [family.id],
          User => [user.id]
        )
      end
    end

    context 'when relation is given' do
      let(:record_or_relation) { Family.where(id: family.id) }

      it 'returns related ids' do
        related_ids = call.transform_values(&:ids).select { |_, val| val.present? }

        expect(related_ids).to eq(
          Family => [family.id],
          User => [user.id]
        )
      end
    end
  end
end
