# frozen_string_literal: true

require 'net/http'
require 'json'

namespace 'pools' do
  desc 'Update pool database'
  task fetch: :environment do |_action|
    Pool.fetch!
  end
end
