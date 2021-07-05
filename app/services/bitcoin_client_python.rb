# frozen_string_literal: true

class BitcoinClientPython
  include ::BitcoinUtil

  def initialize(node_id, name_with_version, coin, client_type, client_version)
    @coin = coin
    @client_type = client_type
    @client_version = client_version
    @node_id = node_id
    @name_with_version = name_with_version
    @mock_connection_error = false
    @mock_block_pruned_error = false
    @mock_partial_file_error = false
    @mock_extra_inflation = 0
  end

  def set_python_node(node)
    @node = node
  end

  def mock_connection_error(status)
    @mock_connection_error = status
  end

  def mock_partial_file_error(status)
    @mock_partial_file_error = status
  end

  def mock_set_extra_inflation(amount)
    @mock_extra_inflation = amount
  end

  def mock_block_pruned_error(status)
    @mock_block_pruned_error = status
  end

  def mock_version(version)
    @client_version = version
  end

  def addnode(node, command)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      throw 'Specify node and node_id' if node.nil? || command.nil?
      @node.addnode(node, command)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "addnode(#{node}, #{command}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def createwallet(wallet_name: '', disable_private_keys: false, blank: false, passphrase: '', avoid_reuse: false, descriptors: true)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.createwallet(wallet_name, disable_private_keys, blank, passphrase, avoid_reuse, descriptors)
    rescue PyCall::PyError => e
      raise BitcoinUtil::RPC::Error, "createwallet failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def importdescriptors(descriptors)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.importdescriptors(descriptors)
    rescue PyCall::PyError => e
      raise BitcoinUtil::RPC::Error, "importdescriptors failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  # Only used in tests
  def bumpfee(tx_id)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error
    raise BitcoinUtil::RPC::PartialFileError if @mock_partial_file_error
    raise BitcoinUtil::RPC::BlockPrunedError if @mock_block_pruned_error
    raise BitcoinUtil::RPC::Error, 'Specify transaction id' unless tx_id.present?

    begin
      @node.bumpfee(tx_id)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "bumpfee(#{tx_id}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  # TODO: add address, node_id params, this can only be called from Python atm
  def disconnectnode(params)
    address = params['address']
    node_id = params['nodeid']
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      throw 'Specify address or node_id' if address.nil? && node_id.nil?
      if address.nil?
        @node.disconnectnode(nodeid: node_id)
      elsif node_id.nil?
        @node.disconnectnode(address: address)
      else
        @node.disconnectnode(address: address, nodeid: node_id)
      end
    rescue Error => e
      raise BitcoinUtil::RPC::Error,
            "disconnectnode(#{address}, #{node_id}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def getblock(block_hash, verbosity, _timeout = nil)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error
    raise BitcoinUtil::RPC::PartialFileError if @mock_partial_file_error
    raise BitcoinUtil::RPC::BlockPrunedError if @mock_block_pruned_error
    raise BitcoinUtil::RPC::Error, 'Specify block hash' unless block_hash.present?

    begin
      @node.getblock(blockhash = block_hash, verbosity = verbosity) # rubocop:disable Lint/SelfAssignment
    rescue PyCall::PyError => e
      raise BitcoinUtil::RPC::BlockNotFoundError if e.message.include?('Block not found')
    rescue Error => e
      raise BitcoinUtil::RPC::Error,
            "getblock(#{block_hash}, #{verbosity}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def getblockhash(height)
    @node.getblockhash(height = height) # rubocop:disable Lint/SelfAssignment
  rescue Error => e
    raise BitcoinUtil::RPC::Error, "getblockhash #{height} failed for #{@coin} #{@name_with_version} (id=#{@node_id}): " + e.message
  end

  def getblockheader(block_hash, verbose = true)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error
    raise BitcoinUtil::RPC::MethodNotFoundError if @client_version < 120_000
    raise BitcoinUtil::RPC::PartialFileError if @mock_partial_file_error
    raise BitcoinUtil::RPC::Error, 'Specify block hash' unless block_hash.present?

    begin
      @node.getblockheader(blockhash = block_hash, verbose = verbose) # rubocop:disable Lint/SelfAssignment
    rescue Error => e
      raise BitcoinUtil::RPC::Error,
            "getblockheader(#{block_hash}, #{verbose}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def getblockchaininfo
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.getblockchaininfo
    rescue PyCall::PyError => e
      raise BitcoinUtil::RPC::Error, "getblockchaininfo failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def getinfo
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.getinfo
    rescue NoMethodError => e
      raise BitcoinUtil::RPC::Error, "getinfo undefined for #{@name_with_version} (id=#{@node_id}): " + e.message
    rescue PyCall::PyError => e
      raise BitcoinUtil::RPC::Error, "getinfo failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def getpeerinfo
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.getpeerinfo
    rescue PyCall::PyError => e
      raise BitcoinUtil::RPC::Error, "getpeerinfo failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def getnetworkinfo
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.getnetworkinfo
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "getnetworkinfo failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def getnewaddress
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.getnewaddress
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "getnewaddress failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def generate(n)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      coinbase_dest = @node.get_deterministic_priv_key.address
      @node.generatetoaddress(n, coinbase_dest)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "generatetoaddress failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def generatetoaddress(n, address)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.generatetoaddress(n, address)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "generatetoaddress failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def getchaintips
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.getchaintips
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "getchaintips failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def getbestblockhash
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.getbestblockhash
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "getbestblockhash failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def getrawtransaction(hash, verbose = false, block_hash = nil)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error
    raise BitcoinUtil::RPC::Error, 'Specify transaction hash' unless hash.present?

    begin
      if block_hash.present?
        @node.getrawtransaction(hash, verbose, block_hash)
      else
        @node.getrawtransaction(hash, verbose)
      end
    rescue Error => e
      raise BitcoinUtil::RPC::Error,
            "getrawtransaction(#{hash}, #{verbose}, #{block_hash}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def getmempoolinfo
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.getmempoolinfo
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "getmempoolinfo failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def gettxoutsetinfo
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      info = @node.gettxoutsetinfo
      if @mock_extra_inflation.positive?
        info = info.collect { |k, v| [k, k == 'total_amount' ? (v.to_f + @mock_extra_inflation) : v] }.to_h
      end
      info
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "gettxoutsetinfo failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def invalidateblock(block_hash)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error
    raise BitcoinUtil::RPC::Error, 'Specify block hash' unless block_hash.present?

    begin
      @node.invalidateblock(blockhash = block_hash)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "invalidateblock(#{block_hash}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def reconsiderblock(block_hash)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error
    raise BitcoinUtil::RPC::Error, 'Specify block hash' unless block_hash.present?

    begin
      @node.reconsiderblock(blockhash = block_hash)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "reconsiderblock(#{block_hash}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def listtransactions
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.listtransactions
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "listtransactions failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def sendrawtransaction(tx)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error
    raise BitcoinUtil::RPC::Error, 'Specify transaction' unless tx.present?

    begin
      @node.sendrawtransaction(tx)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "sendrawtransaction(#{tx}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def gettransaction(tx)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error
    raise BitcoinUtil::RPC::Error, 'Specify transaction' unless tx.present?

    begin
      @node.gettransaction(tx)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "gettransaction(#{tx}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def abandontransaction(tx)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error
    raise BitcoinUtil::RPC::Error, 'Specify transaction' unless tx.present?

    begin
      @node.abandontransaction(tx)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "abandontransaction(#{tx}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def sendtoaddress(destination, amount, comment = '', comment_to = '', subtractfeefromamount = false, replaceable = false)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error
    raise BitcoinUtil::RPC::Error, 'Specify destination' unless destination.present?
    raise BitcoinUtil::RPC::Error, 'Specify amount' unless amount.present?

    begin
      @node.sendtoaddress(address = destination, amount = amount.to_s, comment = comment, comment_to = comment_to, # rubocop:disable Lint/SelfAssignment
                          subtractfeefromamount = subtractfeefromamount, replaceable = replaceable)                # rubocop:disable Lint/SelfAssignment
    rescue Error => e
      raise BitcoinUtil::RPC::Error,
            "sendtoaddress(#{destination}, #{amount}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def testmempoolaccept(txs)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.testmempoolaccept(txs)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "testmempoolaccept failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def walletcreatefundedpsbt(inputs, outputs)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.walletcreatefundedpsbt(inputs, outputs)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "walletcreatefundedpsbt failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def walletprocesspsbt(psbt, sign)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.walletprocesspsbt(psbt, sign)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "walletprocesspsbt failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def finalizepsbt(psbt)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error

    begin
      @node.finalizepsbt(psbt)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "finalizepsbt failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def setnetworkactive(state)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error
    raise BitcoinUtil::RPC::Error, 'Set state to false or true' unless [false, true].include?(state)

    begin
      @node.setnetworkactive(state)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "setnetworkactive(#{block_hash}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def submitblock(block, block_hash = nil)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error
    raise BitcoinUtil::RPC::Error, 'Specify block' unless block.present?

    begin
      @node.submitblock(block)
    rescue Error => e
      raise BitcoinUtil::RPC::Error,
            "submitblock(#{block_hash.presence || block}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end

  def submitheader(header)
    raise BitcoinUtil::RPC::Error, 'Set Python node' if @node.nil?
    raise BitcoinUtil::RPC::ConnectionError if @mock_connection_error
    raise BitcoinUtil::RPC::Error, 'Provide header hex' unless header.present?

    begin
      @node.submitheader(header)
    rescue Error => e
      raise BitcoinUtil::RPC::Error, "submitheader(#{header}) failed for #{@name_with_version} (id=#{@node_id}): " + e.message
    end
  end
end
