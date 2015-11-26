module TestAggregation
  class StepResult
    # TODO: set the proper states
    RESULTS = %w(created passed failed errored pending skipped blocked)

    attr_reader :last_numbers, :test_class, :name, :results

    def initialize(test_class)
      @test_class = test_class

      # Each Job from build matrix has it's own UUID
      # @last_numbers keeps last number for each job (by it's uuid).
      # Keys are step UUID's values are last_number

      @last_numbers = {}

      @results = {}
    end

    def build_result
      test_class.build_result
    end

    def parse(step)
      step_name = step['name']
      fail "Step name not defined for step: #{step.inspect}" unless step_name
      if name && (step_name != name)
        fail "Step name mishmas! (current=#{name}, step.name=#{step_name})"
      end

      # For speed up, this condition could be on the top
      # this way is better for data integrity
      return if step['number'] &&
                step['uuid'] &&
                last_numbers[step['uuid']] &&
                last_numbers[step['uuid']] > step['number']

      @name ||= step_name

      job = test_class.find_job(step['job_id'])

      step_result = step['result']
      # unless RESULTS.include?(step_result)
      #  fail "Unknown step result: #{step_result.inspect}"
      # end

      aggregate_name = build_result.aggregate_by(job)
      results[aggregate_name] ||= {}
      res = results[aggregate_name]
      res[:result] = step_result.downcase if step_result
      if step['data']
        res[:data] ||= {}
        res[:data].update(step['data'])
      end
      @last_numbers[step['uuid']] = step['number']

      self
    end

    def results_hash(opts = {})
      r = {}
      results.each_pair do |machine, res|
        next if opts[:machine] && opts[:machine] != machine
        result = res[:result]
        r[result] ||= 0
        r[result] += 1
      end
      r
    end

    def as_json
      build_result.step_result_constructor(self)
    end
  end
end
