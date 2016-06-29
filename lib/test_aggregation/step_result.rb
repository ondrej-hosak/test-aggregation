module TestAggregation
  # class representing test step
  class StepResult
    # TODO: set the proper states
    RESULTS = %w(created passed failed pending blocked).freeze

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

    def step_result_callback
      test_class.step_result_callback
    end

    def parse(step)
      step_name = step['name']
      raise "Step name not defined for step: #{step.inspect}" unless step_name
      if name && (step_name != name)
        raise "Step name mismatch! (current=#{name}, step.name=#{step_name})"
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

      raise "Unknown step result: #{step_result.inspect}" unless RESULTS.include?(step_result)

      aggregate_name = build_result.aggregate_by(job)
      results[aggregate_name] ||= {}
      res = results[aggregate_name]

      res[:result] = step_result if step_result
      if step['data']
        res[:data] ||= {}
        res[:data].update(step['data'])
      end
      res[:uuid] = step['uuid']
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
      all_states = results.each_with_object([]) do |(_machine, value), result|
        result << build_result.step_status_rewrite_callback(value)
      end

      all_machines = {
        'all' => {
          result: build_result.machine_result(all_states),
          message: '',
          resultId: '00000000-0000-0000-0000-000000000000'
        }
      }

      {
        id: __id__, # temporary id until we can put here vCenter machine id
        description: name,
        machines: results.each_with_object({}) do |(k, v), result|
          result[k] = {
            result: build_result.step_status_rewrite_callback(v),
            message: '',
            resultId: v[:uuid]
          }

          result
        end.merge(all_machines)
      }
    end
  end
end
