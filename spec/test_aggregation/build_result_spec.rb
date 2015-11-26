describe TestAggregation::BuildResults do
  let(:job) { double('Job', id: 1, part_method: 'PART1', machine_method: 'MACHINE1') }
  let(:build) { double('Build', matrix: [job]) }
  let(:subject) do
    TestAggregation::BuildResults.new(
      build,
      ->(job) { job.part_method },
      ->(job) { job.machine_method },
      lambda do |test_step|
        { description: test_step.name, results: test_step.results }
      end
    )
  end
    after(:each) do
      TestAggregation::BuildResults.sum_results =
        TestAggregation::BuildResults.method(:default_sum_results)
    end


  describe 'BuildResults.sum_results=' do
    it 'sets sum_results method' do
      dummy = ->(_results_array) { 'MY-SUM-RESULTS' }
      TestAggregation::BuildResults.sum_results = dummy
      expect(TestAggregation::BuildResults.sum_results({})).to eq(
        'MY-SUM-RESULTS'
      )
    end
  end

  describe 'BuildResults.sum_results' do
    it 'return errored when any only when errored occuerd' do
      expect(
        TestAggregation::BuildResults.sum_results(
          'passed' => 1,
          'errored' => 2,
          'failed' => 1
        )
      ).to eq 'errored'

      expect(
        TestAggregation::BuildResults.sum_results('passed' => 1, 'errored' => 0)
      ).to_not eq 'errored'
    end

    it 'return failed when failed occured and errored not' do
      expect(TestAggregation::BuildResults.sum_results(
               'passed' => 1,
               'failed' => 1
      )).to eq 'failed'
    end

    it 'returns passed when no failed, created and errored steps' do
      expect(
        TestAggregation::BuildResults.sum_results(
          'passed' => 1,
          'skipped' => 1,
          'pending' => 1
        )
      ).to eq 'passed'
    end

    it 'returns created when only created steps exists' do
      expect(
        TestAggregation::BuildResults.sum_results(
          'created' => 1,
          'passed' => 2
        )
      ).to eq 'created'
    end

    it 'returns passed when passed are only passed, pending and skipped and passed state exists' do
      expect(TestAggregation::BuildResults.sum_results('passed' => 1, 'pending' => 1, 'skipped' => 1)).to eq 'passed'
      expect(TestAggregation::BuildResults.sum_results('pending' => 1, 'created' => 1)).to_not eq 'passed'
    end

    it 'raise an exception when unknown result is provided when not errored nor failed' do
      expect do
        TestAggregation::BuildResults.sum_results('unknown' => 1)
      end.to raise_error(/Unknown result/)
    end
  end

  describe '#parse' do
    let(:step_data) do
      {
        'job_id'          => 1,
        'name'            => 'step name',
        'position'        => 1,
        'class_name'      => 'class name',
        'class_position'  => 1
      }
    end

    it 'raise exception when job_id is not specified' do
      expect do
        subject.parse(step_data.update('job_id' => nil))
      end.to raise_error(/Step job_id property is not specified/)
    end

    it 'raise exception when Build does not contain job_id in matrix' do
      expect(job).to receive(:id).and_return(123)
      expect do
        subject.parse(step_data)
      end.to raise_error(/Could not find job for specified job_id/)
    end

    it 'cache and group jobs by parts and machines names' do
      subject.parse(step_data)
      expect(subject.jobs_by_parts_aggregations['PART1']['MACHINE1']).to include(job)
    end

    it 'calls #parse(step) on TestCaseResult instance on `job_id` part & `class_position` position' do
      class_result_double = double('ClassResult', parse: true)
      expect(class_result_double).to receive(:parse).with(step_data)
      subject.parts['PART1'] ||= []
      subject.parts['PART1'][0] = class_result_double
      subject.parse(step_data)
    end
  end

  describe '#results_hash' do
    context 'when no test step results exists' do
      it 'returns { \'created\' => 1 }' do
        empty_test = TestAggregation::BuildResults.new(
          build,
          ->(job) { job.part_method },
          ->(job) { job.machine_method },
          lambda do |test_step|
            { description: test_step.name, results: test_step.results }
          end
        )
        expect(empty_test.results_hash).to eq('created' => 1)
      end
    end

    before(:each) do
      tc1 = double('TestCase1', results_hash: { 'passed' => 2, 'errored' => 1 })
      tc2 = double('TestCase2', results_hash: { 'passed' => 3, 'failed' => 2 })
      tc3 = double('TestCase3', results_hash: {
                     'passed' => 5,
                     'errored' => 1,
                     'broken' => 3 }
                  )
      allow(subject).to receive(:parts).and_return('P1' => [tc1, tc2],
                                                   'P2' => [tc3])
    end

    it 'counts results_hash from each test_case' do
      expect(subject.results_hash).to eq('passed' => 10,
                                         'errored' => 2,
                                         'failed' => 2,
                                         'broken' => 3)
    end

    it 'filters results' do
      expect(subject.results_hash(part: 'P1')).to eq('passed' => 5,
                                                     'errored' => 1,
                                                     'failed' => 2)
    end
  end

  describe '#result' do
    it 'calls sum_results on a results_hash' do
      expect(subject).to receive(:results_hash).and_return({})
      expect(TestAggregation::BuildResults).to receive(:sum_results).with({})
      subject.result
    end
  end

  describe '#as_json' do
    it 'returns array of hashes for each part' do
      expect(subject).to receive(:part_as_json).and_return({}).twice
      expect(subject).to receive(:parts).and_return('P1' => [],
                                                    'P2' => [])
      expect(subject.as_json).to eq [{}, {}]
    end

    it '#part_as_json' do
      job = double('Job', id: 1)
      expect(subject).to receive(:parts).and_return({ 'PART1' => [] }).at_least(1)
      expect(subject).to receive(:jobs_by_parts_aggregations)
        .and_return('PART1' => { 'MACHINE1' => [job] }).at_least(1)
      expect(subject.send(:part_as_json, 'PART1')).to eq(
        name: 'PART1',
        result: 'created',
        machines: [{
          os: 'MACHINE1',
          result: 'created',
          id: 1
        }],
        testCases: []
      )
    end
  end
end
