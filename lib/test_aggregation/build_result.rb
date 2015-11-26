require 'set'
require 'test_aggregation/class_result'

module TestAggregation
  class BuildResults
    attr_reader :build
    attr_reader :parts, :jobs_by_parts_aggregations

    class << self
      def sum_results(results)
        r = results.reject { |_res, count| count <= 0 }.keys.uniq

        # when 'errored' step exists
        return 'errored' if r.include?('errored')

        # when 'failed' step exists
        return 'failed' if r.include?('failed')

        # when all are 'created', then created
        # when all are 'pending', then pending
        return r.first if r.size == 1 && StepResult::RESULTS.include?(r.first)

        return 'passed' if
          r.include?('passed') &&
          (r - %w(passed pending skipped)).empty?

        # when 'created' exists, e.g. test is still running
        return 'created' if r.include?('created')

        # when no results
        return 'errored' if r.empty?

        fail "Unknown result for: #{r.inspect}"
      end
    end

    def initialize(build,
                   job_part_callback,
                   job_aggregate_callback,
                   step_result_callback
                  )
      @build = build

      @job_part_callback = job_part_callback
      @job_aggregate_callback = job_aggregate_callback
      @step_result_callback = step_result_callback

      @parts = {}
      @jobs_by_parts_aggregations = {}
    end

    def aggregate_by(job)
      @job_aggregate_callback[job]
    end

    def part_by(job)
      @job_part_callback[job]
    end

    def step_result_constructor(step_result)
      @step_result_callback[step_result]
    end

    def find_job(job_id)
      build.matrix.find { |j| j.id == job_id }
    end

    def parse(step)
      step_job_id = step['job_id']
      fail 'Step job_id property is not specified' unless step_job_id
      job = find_job(step_job_id)
      fail "Could not find job for specified job_id:#{step_job_id}" unless job

      part_name = part_by(job)
      aggregate_name = aggregate_by(job)

      @parts[part_name] ||= []

      test_cases = parts[part_name]
      @jobs_by_parts_aggregations[part_name] ||= {}
      @jobs_by_parts_aggregations[part_name][aggregate_name] ||= Set.new
      @jobs_by_parts_aggregations[part_name][aggregate_name] << job

      class_position = step['class_position']
      unless class_position
        fail "Class position is undefined. Cannot parse step: #{step.inspect}"
      end
      class_position = class_position.to_i - 1

      test_cases[class_position] ||= ClassResult.new(self)
      test_cases[class_position].parse(step)
    end

    def result(opts = {})
      self.class.sum_results(results_hash(opts))
    end

    def results_hash(opts = {})
      res = parts.each_with_object({}) do |(part, test_cases), obj|
        next if opts[:part] && opts[:part] != part
        test_cases.each do |test_case|
          next unless test_case
          test_case.results_hash(opts).each do |state_name, state_value|
            obj[state_name] ||= 0
            obj[state_name] += state_value
          end
        end
      end
      return { 'created' => 1 } if res.empty?
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
        result: result(part: part_name),
        machines: jobs_by_parts_aggregations[part_name].keys.map do |machine_name|
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
        result: result(part: part_name, machine: machine_name),
        id: job_id
      }
    end
  end
end
