import React from 'react';
import ReactDOM from 'react-dom';

import axios from 'axios';

import { shallow, configure } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
configure({ adapter: new Adapter() });

import InflatedBlockAlerts from 'forkMonitorApp/components/inflatedBlockAlerts';

jest.mock('axios');

function flushPromises() {
  return new Promise(resolve => setImmediate(resolve));
}

axios.get.mockImplementation(url => {
  if (url == "/api/v1/invalid_blocks?coin=BCH") {
    return Promise.resolve({data: [
    ]})
  } else if (url == "/api/v1/inflated_blocks?coin=BCH") {
      return Promise.resolve({data: [{id: 1}]})
    } else if (url == "/api/v1/inflated_blocks?coin=BTC") {
      return Promise.resolve({data: [
      ]})
    } else {
    return Promise.reject({})
  }
});

test('should show inflated block', async () => {
  const wrapper = shallow(<InflatedBlockAlerts coin='BCH' />);
  await flushPromises();
  expect(wrapper.text()).toContain("<AlertInflation />");
});
