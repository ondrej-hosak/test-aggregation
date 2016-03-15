require 'test_aggregation/step_result'

module TestAggregation
  class ClassResult
    attr_reader :build_result
    attr_reader :test_steps
    attr_reader :name

    def initialize(build_result)
      @build_result = build_result
      @test_steps = []
    end

    def step_result_callback
      build_result.step_result_callback
    end

    def find_job(job_id)
      build_result.find_job(job_id)
    end

    def results_hash(opts = {})
      test_steps.each_with_object({}) do |step, obj|
        next unless step
        step_result = step.results_hash(opts)
        step_result.each do |state_name, state_value|
          obj[state_name] ||= 0
          obj[state_name] += state_value
        end
      end
    end

    def parse(step)
      # FIXME: use only class_name
      class_name = step['class_name'] || step['classname']

      fail "Class name not defined for step: #{step.inspect}" unless class_name
      if name && name != class_name
        fail "Class name mishmash: current=#{name}, step.class_name=#{class_name}"
      end

      @name ||= class_name

      step_position = step['position']
      unless step_position
        fail "Step position is undefined. Cannot parse step: #{step.inspect}"
      end
      step_position = step_position.to_i - 1

      @test_steps[step_position] ||= StepResult.new(self)
      @test_steps[step_position].parse(step)
    end

    def as_json
      {
        description: name,
        result: BuildResults.sum_results(results_hash),
        testSteps: test_steps.map do |test_step|
          next unless test_step
          test_step.as_json
        end
      }
    end
  end
end
