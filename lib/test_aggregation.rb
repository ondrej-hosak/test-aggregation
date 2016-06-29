require 'test_aggregation/version'
require 'test_aggregation/build_result'
require 'logger'

# Test aggregation module
module TestAggregation
  class << self
    # rubocop:disable TrivialAccessors
    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def logger=(l)
      @logger = l
    end
    # rubocop:enable TrivialAccessors
  end
end
