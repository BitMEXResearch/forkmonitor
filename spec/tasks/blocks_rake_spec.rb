# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

# rubocop:disable RSpec/MultipleDescribes
# rubocop:disable RSpec/DescribeClass
# rubocop:disable RSpec/NamedSubject
describe 'blocks:fetch_ancestors' do
  include_context 'with rake'

  it 'calls :fetch_ancestors! on Node' do
    expect(Node).to receive(:fetch_ancestors!).with(1)
    subject.invoke('1')
  end
end

describe 'blocks:check_inflation' do
  include_context 'with rake'

  it 'calls check_inflation! on Block for coin' do
    expect(InflatedBlock).to receive(:check_inflation!).with({ coin: :btc, max: nil })
    subject.invoke('BTC')
  end
end

describe 'blocks:check_lightning' do
  include_context 'with rake'

  it 'calls check! for a given coin' do
    expect(LightningTransaction).to receive(:check!).with({ coin: :btc, max: 10_000 })
    subject.invoke('BTC')
  end
end

describe 'blocks:match_missing_pools' do
  include_context 'with rake'

  it 'calls match_missing_pools! for a given coin' do
    expect(Block).to receive(:match_missing_pools!).with(:btc, 100)
    subject.invoke('BTC', '100')
  end
end

describe 'blocks:stale_candidates' do
  include_context 'with rake'

  it 'calls StaleCandidate.process! for a given coin' do
    expect(StaleCandidate).to receive(:process!).with(:btc)
    subject.invoke('BTC')
  end
end
# rubocop:enable RSpec/NamedSubject
# rubocop:enable RSpec/DescribeClass
# rubocop:enable RSpec/MultipleDescribes
