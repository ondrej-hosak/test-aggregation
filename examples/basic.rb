$LOAD_PATH << 'lib'

require 'pp'
require 'test_aggregation'

# dummy example class for job
class Job
  attr_reader :id, :build
  attr_reader :machine_name, :part, :state

  def initialize(id, build, part, machine_name, state)
    @id = id

    @build = build
    @part = part
    @machine_name = machine_name
    @state = state
  end
end

# dummy example class for build
class Build
  def initialize
    @matrix = []
  end

  attr_reader :matrix

  def add_job(job)
    @matrix << job
  end
end

build = Build.new
build.add_job(Job.new(1, build, 'PART1', 'XP', 'created'))
build.add_job(Job.new(2, build, 'PART1', 'VISTA', 'created'))

build_results = TestAggregation::BuildResults.new(
  build,
  ->(job) { job.part },
  ->(job) { job.machine_name },
  lambda do |step_result|
    begin
      step_result[:data]['status'].split('_').collect(&:capitalize).join
    rescue
      return 'NotSet' if step_result[:result] == 'created'
      return 'NotTested' if step_result[:result] == 'blocked'
      step_result[:result].capitalize
    end
  end
)

step1 = {
  'class_name'      => 'test_case_1',
  'class_position'  => 1,
  'name'            => 'test_step_1_1',
  'position'        => 1,
  # 'job_id'          => ...,
  # 'result'          => ....
}

step2 = {
  'class_name'      => 'test_case_2',
  'class_position'  => 2,
  'name'            => 'test_step_2_1',
  'position'        => 1,
  # 'job_id'          => ...,
  # 'result'          => ....
}

data_status = { 'status' => 'not_performed' }

build_results.parse(step1.update('job_id' => 1, 'result' => 'passed'))
build_results.parse(step1.update('job_id' => 2, 'result' => 'pending', 'data' => data_status))
build_results.parse(step2.update('job_id' => 1, 'result' => 'failed'))
build_results.parse(step2.update('job_id' => 2, 'result' => 'blocked'))

pp build_results.as_json
