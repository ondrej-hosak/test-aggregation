require 'set'
require 'test_aggregation/class_result'

module TestAggregation
  # class representing build
  class BuildResults
    attr_reader :build
    attr_reader :parts, :jobs_by_parts_aggregations, :step_result_callback

    def initialize(build,
                   job_part_callback,
                   job_aggregate_callback,
                   step_status_rewrite_callback
                  )
      @build = build

      @job_part_callback = job_part_callback
      @job_aggregate_callback = job_aggregate_callback
      @step_status_rewrite_callback = step_status_rewrite_callback

      @parts = {}
      @jobs_by_parts_aggregations = {}
      @jobs_by_parts = {}
    end

    def aggregate_by(job)
      @job_aggregate_callback[job]
    end

    def part_by(job)
      @job_part_callback[job]
    end

    def step_status_rewrite_callback(step_result)
      @step_status_rewrite_callback[step_result]
    end

    def find_job(job_id)
      build.matrix.find { |j| j.id == job_id }
    end

    def parse(step)
      step_job_id = step['job_id']
      raise 'Step job_id property is not specified' unless step_job_id
      job = find_job(step_job_id)
      raise "Could not find job for specified job_id:#{step_job_id}" unless job
      class_position = step['class_position']
      raise "Class position is undefined. Cannot parse step: #{step.inspect}" unless class_position

      part_name = part_by(job)
      aggregate_name = aggregate_by(job)

      @parts[part_name] ||= []

      test_cases = parts[part_name]

      @jobs_by_parts_aggregations[part_name] ||= {}
      @jobs_by_parts_aggregations[part_name][aggregate_name] ||= []
      @jobs_by_parts_aggregations[part_name][aggregate_name] << job

      @jobs_by_parts[part_name] ||= []
      @jobs_by_parts[part_name] << job

      # zero indexing
      class_position = class_position.to_i - 1

      test_cases[class_position] ||= ClassResult.new(self)
      test_cases[class_position].parse(step)
    end

    def test_case_result(results)
      r = results.reject { |_res, count| count <= 0 }.keys.uniq.compact.map(&:to_s)

      return 'Failed' if r.empty?

      return 'Failed' if r.include?('failed') || r.include?('blocked')

      return 'Passed' if r.all? { |result| ['passed', 'pending'].include?(result) }

      return 'Loading' if r.include?('created')

      TestAggregation.logger.error "Unknown result for: #{r.inspect}"
      'Errored'
    end

    def part_result(part_name)
      jobs = @jobs_by_parts[part_name]
      return 'Created' unless jobs

      job_results = jobs.map(&:state).uniq

      return 'Failed' if job_results.include?('failed') || job_results.include?('canceled')
      return 'Created' if job_results.include?('created')

      'Passed'
    end

    def machine_result(results)
      return 'Passed' if results.all? { |r| ['Passed', 'Skipped', 'NotPerformed'].include?(r) }

      return 'Failed' if results.include? 'Failed'
      return 'Skipped' if results.include? 'Skipped'
      return 'Invalid' if results.include? 'Invalid'
      return 'NotTested' if results.include? 'NotTested'
      return 'KnownBug' if results.include? 'KnownBug'
      return 'NotSet' if results.include? 'NotSet'
      return 'Passed' if results.include? 'Passed'

      'NotPerformed'
    end

    def results_hash(opts = {})
      res = parts.each_with_object({}) do |(part, test_cases), obj|
        next if opts[:part] && opts[:part] != part
        test_cases.each do |test_case|
          next unless test_case
          test_case.class_results_hash(opts).each do |state_name, state_value|
            obj[state_name] ||= 0
            obj[state_name] += state_value
          end
        end
      end
      return { 'created' => 1 } if res.empty?
      res
    end

    # this method return hash with rewrited states from new to old ones
    # it is used for evaluating machine result that is evaluated from old states
    def new_states_results_hash
      res = parts.each_with_object({}) do |(_part, test_cases), obj|
        test_cases.each do |test_case|
          next unless test_case
          test_case.test_steps.each do |test_step|
            test_step.results.each do |(_machine, value)|
              step_rewrited_name = @step_status_rewrite_callback.call(value)
              obj[step_rewrited_name] ||= 0
              obj[step_rewrited_name] += 1
            end
          end
        end
      end
      return { 'NotSet' => 1 } if res.empty?

      res
    end

    def as_json
      parts.each_with_object([]) do |(part_name, _test_cases), obj|
        obj << part_as_json(part_name)
      end
    end

    private

    def part_as_json(part_name)
      test_cases = parts[part_name]
      {
        name: part_name,
        result: part_result(part_name),
        machines: jobs_by_parts_aggregations[part_name].keys.map do |machine_name|
          puts machine_name
          machines_as_json(part_name, machine_name)
        end,
        testCases: test_cases.map do |test_case|
          next unless test_case
          test_case.as_json
        end
      }
    end

    def machines_as_json(part_name, machine_name)
      jobs = jobs_by_parts_aggregations[part_name][machine_name]
      job_id = begin
                 jobs.first.id
               rescue
                 0
               end # What to do when zero or more jobs is defined?
      {
        os: machine_name,
        result: jobs.first.state == 'canceled' ? 'Failed' : jobs.first.state.capitalize,
        id: job_id
      }
    end
  end
end
