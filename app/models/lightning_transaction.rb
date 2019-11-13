class LightningTransaction < ApplicationRecord
  belongs_to :block

  def self.check!(options)
    throw "Only BTC mainnet supported" unless options[:coin].nil? || options[:coin] == :btc
    max = options[:max].present? ? options[:max] : 10
    node = Node.bitcoin_core_by_version.first
    puts "Scan blocks for relevant Lightning transactions using #{ node.name_with_version }..." unless Rails.env.test?

    blocks_to_check = [node.block]
    block = node.block
    while true
      # Don't perform lightning checks for more than 10 (default) blocks; it will take too long to catch up
      if blocks_to_check.count > max
        max_exceeded = true
        break
      end
      throw "Unable to perform lightning checks due to missing intermediate block" if block.parent.nil?
      block = block.parent
      break if block.checked_lightning
      blocks_to_check.unshift(block)
    end

    blocks_to_check.each do |block|
      self.check_penalties!(block, node)
      block.update checked_lightning: true
    end

    if max_exceeded
      raise "More than #{ max } blocks behind for lightning checks, please manually check blocks before #{ blocks_to_check.first.height } (#{ blocks_to_check.first.block_hash })"
    end
  end

  def self.check_penalties!(block, node)
    raw_block = node.client.getblock(block.block_hash, 0)
  end

end
