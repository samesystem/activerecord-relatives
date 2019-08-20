# frozen_string_literal: true

require 'rails_helper'

module ActiveRecord::Relatives
  RSpec.describe DependentHash do
    subject(:dependent_hash) { described_class.new }

    describe '#set' do
      context 'when updating same key twice' do
        before do
          dependent_hash.set(:not_dependent) { ['b'] }
        end

        it 'raises error' do
          expect { dependent_hash.set(:not_dependent) { ['a'] } }
            .to raise_error('trying to add same key twice not_dependent')
        end
      end

      context 'when creating circular dependency' do
        before do
          # dependency: dependent1 -> dependent2 -> dependent4 -> dependent3 -> dependent2
          dependent_hash.set(:dependent4, depends_on: %i[dependent3]) { [3] }
          dependent_hash.set(:dependent3, depends_on: %i[not_dependent dependent2]) { [3] }
        end

        it 'raises error' do
          expect { dependent_hash.set(:dependent2, depends_on: %i[dependent4]) { [2] } }
            .to raise_error(ActiveRecord::Relatives::DependentHash::CircularDependencyError)
        end
      end
    end

    describe '#result' do
      subject(:result) { dependent_hash.result }

      context 'when no dependencies exist' do
        before do
          dependent_hash.set(:not_dependent) { ['a'] }
          dependent_hash.set(:not_dependent2) { ['b'] }
        end

        it 'returns full result' do
          expect(result).to eq(not_dependent: ['a'], not_dependent2: ['b'])
        end
      end

      context 'when some dependencies exist' do
        before do
          dependent_hash.set(:dependent2, depends_on: [:dependent1]) { ['c'] }
          dependent_hash.set(:dependent1, depends_on: [:not_dependent]) { ['b'] }
          dependent_hash.set(:not_dependent) { ['a'] }
        end

        it 'returns full result' do
          expect(result).to eq(not_dependent: ['a'], dependent1: ['b'], dependent2: ['c'])
        end

        context 'when after_dependency_resolve hook is set' do
          it 'triggers hooks' do
            triggered_values = []
            dependent_hash.before_dependency_resolve do |info|
              triggered_values << info[:partial_result]
            end

            dependent_hash.result
            expect(triggered_values).to eq([
              ['a'], ['b'], ['c']
            ])
          end
        end
      end

      context 'when some dependencies can not be satisfied' do
        before do
          dependent_hash.set(:dependent1, depends_on: [:does_not_exist]) { ['b'] }
          dependent_hash.set(:not_dependent) { ['a'] }
        end

        it 'raises error' do
          expect { result }
            .to raise_error('Some dependencies can not be satisfied: dependent1 depends on does_not_exist')
        end
      end
    end
  end
end
