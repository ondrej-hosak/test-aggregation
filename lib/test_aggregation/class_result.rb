require 'test_aggregation/step_result'

module TestAggregation
  # class representing test case
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

    def class_results_hash(opts = {})
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

      raise "Class name not defined for step: #{step.inspect}" unless class_name

      if name && name != class_name
        raise "Class name mismatch: current=#{name}, step.class_name=#{class_name}"
      end

      @name ||= class_name

      step_position = step['position']
      raise "Step position is undefined. Cannot parse step: #{step.inspect}" unless step_position

      step_position = step_position.to_i - 1

      @test_steps[step_position] ||= StepResult.new(self)
      @test_steps[step_position].parse(step)
    end

    def as_json
      {
        description: name,
        result: build_result.test_case_result(class_results_hash),
        testSteps: test_steps.map do |test_step|
          next unless test_step
          test_step.as_json
        end
      }
    end
  end
end
