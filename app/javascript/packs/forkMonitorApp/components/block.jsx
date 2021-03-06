import React from 'react';
import axios from 'axios';

import Explorer from './explorer';
import BlockInfo from './blockInfo';
import Transaction from './transaction';

import NumberFormat from 'react-number-format';

import {
    Breadcrumb,
    BreadcrumbItem,
    Col,
    Container,
    TabPane,
    Row,
    Table
} from 'reactstrap';

class Block extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      coin: props.match.params.coin,
      hash: props.match.params.hash,
      block: null,
    };
  }

  componentDidMount() {
    this.getBlock(this.state.coin, this.state.hash);
  }

  getBlock(coin, hash) {
    axios.get('/api/v1/blocks/hash/' + hash).then(function (response) {
      return response.data;
    }).then(function (block) {
      this.setState({
        block: block,
      });
      }.bind(this)).catch(function (error) {
        console.error(error);
      });
   }

  render() {
    const coin = this.state.coin;
    return(
      <TabPane align="left" >
        <Container>
          <Row><Col>
            <Breadcrumb className="chaintip-header">
              <BreadcrumbItem className="chaintip-hash">
                { this.state.hash } ({ coin.toUpperCase() })
              </BreadcrumbItem>
            </Breadcrumb>
            { this.state.block &&
              <BlockInfo block={ this.state.block } extra />
            }
            <div>
              <h3>Predicted block transactions</h3>
              <p>We call <code>getblocktemplate</code> on our node several times
              per minute to construct a candidate block. We then check to see if
              the real block contains the same transactions. Usually any difference
              is due to timing coincidence and variations for how transactions
              propagate between nodes.</p>
              { this.state.block && this.state.block.template_txs_fee_diff &&
                <p>
                  This block contained <NumberFormat value={ Math.abs(this.state.block.template_txs_fee_diff) } displayType={'text'} decimalScale={8} fixedDecimalScale={true} /> BTC {
                    this.state.block.template_txs_fee_diff > 0 ? "more " : "less "
                  }
                  transaction fees than expected from our most recent template.
                </p>
              }
              { this.state.block &&
                <p>
                  For a similar analysis see <a href={"https://miningpool.observer/template-and-block/" + this.state.block.hash}>miningpool.observer</a>.
                </p>
              }
            </div>
            { this.state.block && this.state.block.tx_ids_omitted &&
              <div>
                <h3>Transactions we expected in block</h3>
                <p>
                  The transactions below were present in our most recent block template,
                  but not found in the final block. If a pool systematically leaves out certain
                  transactions, this could indicate censorship.
                </p>
                { this.state.block.lowest_template_fee_rate != null &&
                  <p>
                    The lowest fee in the block template was { this.state.block.lowest_template_fee_rate } sat / vbyte.
                    We ignore transactions less than 5 sat / byte above this.
                  </p>
                }
                <Table striped responsive className="conflicting-transactions">
                  <thead>
                    <tr align="left">
                      <th style={ {width: "75pt"} }>Explorer</th>
                      <th style={ {width: "75pt"} }>sat / byte</th>
                      <th>Transaction id</th>
                    </tr>
                  </thead>
                  <tbody>
                    {this.state.block.tx_ids_omitted.map(function (tx, index) {
                      return (
                        <Transaction key={index} coin={ coin } tx_id={ tx[0] } fee_rate={ tx[1] }/>
                      )
                    })}
                  </tbody>
                </Table>
                <h3>Unexpected transactions in block</h3>
                <p>
                  The transactions below were not present in our most recent block
                  template, but were in the final block. If a pool systematically
                  includes transactions that were not in the mempool, they might
                  be receiving transactions privately. If a transaction was in the mempool,
                  but paid a fee much too low to be included in a block, this could
                  indicate out of band fee payment.
                </p>
                <Table striped responsive className="conflicting-transactions">
                  <thead>
                    <tr align="left">
                      <th style={ {width: "75pt"} }>Explorer</th>
                      <th>Transaction id</th>
                    </tr>
                  </thead>
                  <tbody>
                    {this.state.block.tx_ids_added.map(function (tx, index) {
                      return (
                        <Transaction key={index} coin={ coin } tx_id={ tx[0] } />
                      )
                    })}
                  </tbody>
                </Table>
              </div>
            }
          </Col></Row>
        </Container>
      </TabPane>
    )
  }
}

export default Block
