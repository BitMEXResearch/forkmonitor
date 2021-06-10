# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Softfork, type: :model do
  let(:node) { create(:node_with_block, version: 200_000) }

  describe 'process' do
    it 'should do nothing if no forks are active' do
      blockchaininfo = {
        'chain' => 'main',
        'softforks' => {
        }
      }
      Softfork.process(node, blockchaininfo)
      expect(Softfork.count).to eq(0)
    end

    it 'should add an active bip9 softfork' do
      blockchaininfo = {
        'chain' => 'main',
        'softforks' => {
          'segwit' => {
            'type' => 'bip9',
            'bip9' => {
              'status' => 'active',
              'bit' => 1,
              'height' => 481_824
            }
          }
        }
      }
      Softfork.process(node, blockchaininfo)
      expect(Softfork.count).to eq(1)

      # If a softfork status is not "defined" when a node is first polled, consider
      # it a status change and send notification:
      expect(Softfork.first.notified_at).to be_nil

      # And not more than once
      Softfork.process(node, blockchaininfo)
      expect(Softfork.count).to eq(1)
    end

    it 'should handle a status update' do
      blockchaininfo = {
        'chain' => 'main',
        'softforks' => {
          'segwit' => {
            'type' => 'bip9',
            'bip9' => {
              'status' => 'defined',
              'bit' => 1,
              'height' => 470_000
            }
          }
        }
      }
      Softfork.process(node, blockchaininfo)
      expect(Softfork.count).to eq(1)
      expect(Softfork.first.status).to eq('defined')
      # Don't notify when status is defined
      expect(Softfork.first.notified_at).not_to be_nil

      blockchaininfo = {
        'chain' => 'main',
        'softforks' => {
          'segwit' => {
            'type' => 'bip9',
            'bip9' => {
              'status' => 'active',
              'bit' => 1,
              'height' => 481_824
            }
          }
        }
      }
      Softfork.process(node, blockchaininfo)
      expect(Softfork.count).to eq(1)
      expect(Softfork.first.status).to eq('active')
      # Status change should trigger notification
      expect(Softfork.first.notified_at).to be_nil
    end

    it 'should parse pre 0.19 format' do
      node.version = 180_100
      blockchaininfo = {
        'chain' => 'main',
        'bip9_softforks' => {
          'segwit' => {
            'status' => 'active',
            'height' => 481_824
          }
        }
      }
      Softfork.process(node, blockchaininfo)
      expect(Softfork.count).to eq(1)

      # And not more than once
      Softfork.process(node, blockchaininfo)
      expect(Softfork.count).to eq(1)
    end

    it 'should ignore burried softforks' do
      blockchaininfo = {
        'chain' => 'main',
        'softforks' => {
          'bip66' => {
            'type' => 'buried',
            'active' => true,
            'height' => 363_725
          }
        }
      }
      Softfork.process(node, blockchaininfo)
      expect(Softfork.count).to eq(0)
    end
  end
end
