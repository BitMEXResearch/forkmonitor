# frozen_string_literal: true

namespace 'debug' do
  if Rails.env.test? || Rails.env.development?
    require 'pycall/import'
    include PyCall::Import
    pyimport :sys
    sys.path.insert(0, '.')
  end

  desc 'Print basic info from each node'
  task node_info: :environment do
    Node.all.each do |node|
      puts ''
      puts node.name_with_version.to_s
      if node.block.nil?
        puts 'Tip unknown'
        next
      end
      puts "Height: #{node.block.height}"
      puts "Time  : #{node.block.timestamp}"
      puts "Hash  : #{node.block.block_hash}"
      puts "Work  : #{node.block.work}"
      begin
        node.client.getnetworkinfo
        puts 'Reachable'
      rescue BitcoinClient::Error
        puts 'Unreachable'
      end
    end
  end

  desc 'Spin up and query Bitcoin Core test node'
  task bitcoind: :environment do
    raise 'Not supported on production' if Rails.env.production?

    pyfrom :util, import: :TestWrapper
    test = TestWrapper.new

    test.setup({ loglevel: 'DEBUG' })
    puts test.nodes[0].getnetworkinfo
    test.shutdown
  end
end

task verbose: [:environment] do
  Rails.logger = Logger.new($stdout)
end

desc 'Force rails logger log level to debug'
task debug: %i[environment verbose] do
  Rails.logger.level = Logger::DEBUG
end

desc 'Force rails logger log level to info'
task info: %i[environment verbose] do
  Rails.logger.level = Logger::INFO
end

desc 'Simulate task failure'
task failing_task: :environment do
  puts "Failing task in environment #{Rails.env}..."
  FAIL!
end
