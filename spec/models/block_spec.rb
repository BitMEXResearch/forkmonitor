require "rails_helper"

RSpec.describe Block, :type => :model do
  describe "log2_pow" do
    it "should be log2(pow)" do
      block = create(:block, work: "00000000000000000000000000000001")
      expect(block.log2_pow).to eq(0.0)
      block = create(:block, work: "00000000000000000000000000000002")
      expect(block.log2_pow).to eq(1.0)
    end
  end

  describe "self.pool_from_coinbase_tx" do
    it "should find Antpool" do
      # response from getrawtransaction 99d1ead20f83d090f2878559446abaa5db320524f63011ed1b71bfef47c5ac02 true
      tx = {
        "txid" => "99d1ead20f83d090f2878559446abaa5db320524f63011ed1b71bfef47c5ac02",
        "hash" => "b1bf7d584467258e368199d9851e820176bf06f2208f1e2ec6433f21eac5842d",
        "version" => 1,
        "size"=>252,
        "vsize"=>225,
        "weight"=>900,
        "locktime"=>0,
        "vin"=>[
          {
            "coinbase"=>"0375e8081b4d696e656420627920416e74506f6f6c34381d00330020c85d207ffabe6d6d2bcb43e33b12c011f5e99afe1b4478d1001b7ce90db6b7c937793e89fafae6dd040000000000000052000000eb0b0200",
            "sequence"=>4294967295
          }
        ],
        "vout"=>[
          {
            "value"=>13.31801952,
            "n"=>0,
            "scriptPubKey"=>{"asm"=>"OP_DUP OP_HASH160 edf10a7fac6b32e24daa5305c723f3de58db1bc8 OP_EQUALVERIFY OP_CHECKSIG", "hex"=>"76a914edf10a7fac6b32e24daa5305c723f3de58db1bc888ac", "reqSigs"=>1, "type"=>"pubkeyhash", "addresses"=>["1Nh7uHdvY6fNwtQtM1G5EZAFPLC33B59rB"]}
          }, {
            "value"=>0.0,
            "n"=>1,
            "scriptPubKey"=>{"asm"=>"OP_RETURN aa21a9ed53112dcef82ee73de0243da1fe7278468349c7098fa3db778383005238d28e0a", "hex"=>"6a24aa21a9ed53112dcef82ee73de0243da1fe7278468349c7098fa3db778383005238d28e0a", "type"=>"nulldata"}
          }
        ], "hex"=>"010000000001010000000000000000000000000000000000000000000000000000000000000000ffffffff540375e8081b4d696e656420627920416e74506f6f6c34381d00330020c85d207ffabe6d6d2bcb43e33b12c011f5e99afe1b4478d1001b7ce90db6b7c937793e89fafae6dd040000000000000052000000eb0b0200ffffffff0260af614f000000001976a914edf10a7fac6b32e24daa5305c723f3de58db1bc888ac0000000000000000266a24aa21a9ed53112dcef82ee73de0243da1fe7278468349c7098fa3db778383005238d28e0a0120000000000000000000000000000000000000000000000000000000000000000000000000",
        "blockhash"=>"0000000000000000001e93e79aa71bec43c72d671935e704b0713a4453e04183",
        "confirmations"=>14,
        "time"=>1562242070,
        "blocktime"=>1562242070
      }

      expect(Block.pool_from_coinbase_tx(tx)).to eq("Antpool")
    end

    it "should find F2Pool" do
      # Truncated response from getrawtransaction 87b72be71eab3fb8c452ea91ba0c21c4b9affa56386b0455ad50d3513c433484 true
      tx =  {
        "vin"=>[
          {
            "coinbase" => "039de8082cfabe6d6db6e2235d03234641c5859b7b1864addea7c0c2ef07a68bb8ebc178ac804f4b6910000000f09f909f000f4d696e656420627920776c3337373100000000000000000000000000000000000000000000000000000000050024c5aa2a",
            "sequence" => 0
          }
        ]
      }

      expect(Block.pool_from_coinbase_tx(tx)).to eq("F2Pool")
    end
  end

  describe "self.check_inflation!" do
    before do
      @node = build(:node, version: 170001)
      @node.client.mock_set_height(560176)
      @node.poll!
      @node.reload
      expect(Block.maximum(:height)).to eq(560176)
      allow(Node).to receive(:bitcoin_core_by_version).and_return [@node]
    end

    it "should call gettxoutsetinfo" do
      Block.check_inflation!
      expect(TxOutset.count).to eq(1)
      expect(TxOutset.first.block.height).to eq(560176)
    end

    it "should not create duplicate TxOutset entries" do
      Block.check_inflation!
      Block.check_inflation!
      expect(TxOutset.count).to eq(1)
    end

    describe "two different blocks" do
      before do
        Block.check_inflation!

        @node.client.mock_set_height(560178)
        Block.check_inflation!
      end

      it "should fetch intermediate blocks" do
        expect(Block.maximum(:height)).to eq(560178)
        expect(TxOutset.count).to eq(2)
        expect(TxOutset.last.block.height).to eq(560178)
      end

      it "mock UTXO set should have increase by be 2 x 12.5 BTC" do
        expect(TxOutset.last.total_amount - TxOutset.first.total_amount).to eq(25.0)
      end
    end
  end
end
