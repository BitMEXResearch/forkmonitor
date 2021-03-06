# frozen_string_literal: true

class FeedsController < ApplicationController
  before_action :set_coin,
                only: %i[blocks_invalid inflated_blocks invalid_blocks stale_candidates ln_penalties ln_sweeps
                         ln_uncoops unknown_pools]
  before_action :set_page

  def blocks_invalid
    respond_to do |format|
      format.rss do
        # Blocks are marked invalid during chaintip check
        latest = Chaintip.joins(:block).where('blocks.coin = ?', Block.coins[@coin]).order(updated_at: :desc).first
        if stale?(etag: latest.try(:updated_at), last_modified: latest.try(:updated_at))
          @blocks_invalid = Block.where('blocks.coin = ?',
                                        Block.coins[@coin]).where('array_length(marked_invalid_by,1) > 0').order(height: :desc)
        end
      end
    end
  end

  def inflated_blocks
    respond_to do |format|
      format.rss do
        latest = InflatedBlock.joins(:block).where('blocks.coin = ?', Block.coins[@coin]).order(updated_at: :desc).first
        if stale?(etag: latest.try(:updated_at), last_modified: latest.try(:updated_at))
          @inflated_blocks = InflatedBlock.joins(:block).where('blocks.coin = ?',
                                                               Block.coins[@coin]).order(created_at: :desc)
        end
      end
    end
  end

  def invalid_blocks
    respond_to do |format|
      format.rss do
        latest = InvalidBlock.joins(:block).where('blocks.coin = ?', Block.coins[@coin]).order(updated_at: :desc).first
        @invalid_blocks = InvalidBlock.joins(:block).where('blocks.coin = ?', Block.coins[@coin]).order(height: :desc) if stale?(etag: latest.try(:updated_at), last_modified: latest.try(:updated_at))
      end
    end
  end

  def unknown_pools
    respond_to do |format|
      format.rss do
        latest = Block.where(coin: @coin).order(height: :desc).first
        if stale?(etag: latest.try(:updated_at), last_modified: latest.try(:updated_at))
          @unknown_pools = Block.where(coin: @coin, pool: nil).where('height > ?',
                                                                     latest.height - 10_000).where.not(coinbase_message: nil).order(height: :desc).limit(50)
        end
      end
    end
  end

  def lagging_nodes
    respond_to do |format|
      format.rss do
        latest = Lag.order(updated_at: :desc).first
        @lagging_nodes = Lag.where(publish: true).order(created_at: :desc) if stale?(etag: latest.try(:updated_at), last_modified: latest.try(:updated_at))
      end
    end
  end

  def unreachable_nodes
    respond_to do |format|
      format.rss do
        enabled_nodes = Node.where(enabled: true).order(unreachable_since: :desc, mirror_unreachable_since: :desc)
        @unreachable_nodes = enabled_nodes.where.not(unreachable_since: nil).or(enabled_nodes.where.not(mirror_unreachable_since: nil))
      end
    end
  end

  def version_bits
    respond_to do |format|
      format.rss do
        latest = VersionBit.order(updated_at: :desc).first
        @version_bits = VersionBit.all.order(created_at: :desc) if stale?(etag: latest.try(:updated_at), last_modified: latest.try(:updated_at))
      end
    end
  end

  def stale_candidates
    latest = StaleCandidate.last_updated_cached(@coin)
    if stale?(etag: latest.try(:updated_at), last_modified: latest.try(:updated_at))
      @page_count = Rails.cache.fetch "StaleCandidate.feed.count(#{@coin})" do
        (StaleCandidate.feed.where(coin: @coin).count / StaleCandidate::PER_PAGE.to_f).ceil
      end

      respond_to do |format|
        format.rss do
          @stale_candidates = StaleCandidate.feed.page_cached(@coin, @page)
        end
      end
    end
  end

  def ln_penalties
    respond_to do |format|
      format.rss do
        latest = PenaltyTransaction.last_updated_cached
        if stale?(etag: latest.try(:updated_at), last_modified: latest.try(:updated_at))
          @ln_penalties = []
          @ln_penalties = PenaltyTransaction.all_with_block_cached if @coin == :btc
        end
      end
    end
  end

  def ln_sweeps
    respond_to do |format|
      format.rss do
        latest = SweepTransaction.last_updated_cached
        if stale?(etag: latest.try(:updated_at), last_modified: latest.try(:updated_at))
          @ln_sweeps = []
          if @coin == :btc
            @page_count = Rails.cache.fetch 'SweepTransaction.count' do
              (SweepTransaction.count / SweepTransaction::PER_PAGE.to_f).ceil
            end
            @ln_sweeps = SweepTransaction.page_with_block_cached(@page)
          end
        end
      end
    end
  end

  def ln_uncoops
    respond_to do |format|
      format.rss do
        latest = MaybeUncoopTransaction.last_updated_cached
        if stale?(etag: latest.try(:updated_at), last_modified: latest.try(:updated_at))
          @ln_uncoops = []
          if @coin == :btc
            @page_count = Rails.cache.fetch 'MaybeUncoopTransaction.count' do
              (MaybeUncoopTransaction.count / MaybeUncoopTransaction::PER_PAGE.to_f).ceil
            end
            @ln_uncoops = MaybeUncoopTransaction.page_with_block_cached(@page)
          end
        end
      end
    end
  end

  private

  def set_page
    @page = (params[:page] || 1).to_i
    if @page < 1
      render json: 'invalid param', status: :unprocessable_entity
      nil
    end
  end
end
