$LOAD_PATH << 'lib'

require 'pp'
require 'test_aggregation'

class Job
  attr_reader :id, :build
  attr_reader :browser_name, :part

  def initialize(id, build, part, browser_name)
    @id = id

    @build = build
    @part = part
    @browser_name = browser_name
  end
end

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
build.add_job(Job.new(1, build, 'PART1', 'Chrome'))
build.add_job(Job.new(2, build, 'PART1', 'Firefox'))

build_results = TestAggregation::BuildResults.new(
  build,
  ->(job) { job.part },
  ->(job) { job.browser_name },
  lambda do |test_step|
    { name: test_step.name, aggregated_results: test_step.results }
  end
)

step1 = {
  'class_name'      => 'First class',
  'class_position'  => 1,
  'name'            => 'Our first step',
  'position'        => 1,
  # 'job_id'          => ...,
  # 'result'          => ....
}
build_results.parse(step1.update('job_id' => 1, 'result' => 'passed'))
build_results.parse(step1.update('job_id' => 2, 'result' => 'pending'))

pp build_results.as_json
