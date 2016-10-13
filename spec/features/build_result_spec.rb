describe TestAggregation::BuildResults do
  let(:job) { double('Job', id: 1, part_method: 'PART1', machine_method: 'MACHINE1') }
  let(:build) { double('Build', matrix: [job]) }
  let(:step_data) do
    {
      'job_id'          => 1,
      'name'            => 'step name',
      'position'        => 1,
      'class_name'      => 'class name',
      'class_position'  => 1,
      'result'          => 'passed'
    }
  end
  let(:subject) do
    TestAggregation::BuildResults.new(
      build,
      ->(job) { job.part_method },
      ->(job) { job.machine_method },
      -> (test_step) { test_step[:result] }
    )
  end

  describe '#test_case_result' do
    it 'returns Failed when results are empty' do
      expect(subject.test_case_result({})).to eq 'Failed'
    end

    it 'returns Failed when failed occurred' do
      expect(subject.test_case_result('passed' => 1, 'failed' => 1)).to eq 'Failed'
    end

    it 'returns Failed when blocked occurred' do
      expect(subject.test_case_result('passed' => 1, 'blocked' => 1)).to eq 'Failed'
    end

    it 'returns Passed when all steps are pending or passed' do
      expect(subject.test_case_result('passed' => 1, 'pending' => 1)).to eq 'Passed'
    end

    it 'returns Passed when only pending steps exist' do
      expect(subject.test_case_result('pending' => 1)).to eq 'Passed'
    end

    it 'returns Loading when created steps exist' do
      expect(subject.test_case_result('created' => 1)).to eq 'Loading'
    end

    it 'returns Errored when there are some unrecognised results' do
      expect(subject.test_case_result('exploded' => 1)).to eq 'Errored'
    end
  end

  describe '#part_result' do
    let(:failed_job) do
      double('Job', id: 982, part_method: 'PART1', machine_method: 'MACHINE1', state: 'failed')
    end
    let(:created_job) do
      double('Job', id: 983, part_method: 'PART2', machine_method: 'MACHINE1', state: 'created')
    end
    let(:passed_job) do
      double('Job', id: 984, part_method: 'PART3', machine_method: 'MACHINE1', state: 'passed')
    end
    let(:canceled_job) do
      double('Job', id: 985, part_method: 'PART1', machine_method: 'MACHINE1', state: 'canceled')
    end
    let(:started_job) do
      double('Job', id: 986, part_method: 'PART1', machine_method: 'MACHINE1', state: 'started')
    end

    let(:build) do
      double('Build', matrix: [failed_job, created_job, passed_job, canceled_job, started_job])
    end

    it 'returns Created when there are no jobs' do
      expect(subject.part_result('NOT-EXISTING-PART')).to eq 'Created'
    end

    it 'returns Failed when there are failed jobs' do
      step_data.merge!(
        'job_id' => 982,
        'result' => 'failed'
      )

      subject.parse(step_data)
      expect(subject.part_result('PART1')).to eq 'Failed'
    end

    it 'returns Failed when there are canceled jobs' do
      step_data.merge!(
        'job_id' => 985,
        'result' => 'created'
      )

      subject.parse(step_data)
      expect(subject.part_result('PART1')).to eq 'Failed'
    end

    it 'returns Created when there are created jobs' do
      step_data.merge!(
        'job_id' => 983,
        'result' => 'created'
      )

      subject.parse(step_data)
      expect(subject.part_result('PART2')).to eq 'Created'
    end

    it 'returns Started when there are started jobs' do
      step_data.merge!(
        'job_id' => 986,
        'result' => 'passed'
      )

      subject.parse(step_data)
      expect(subject.part_result('PART1')).to eq 'Started'
    end

    it 'returns Passed when there are passed jobs' do
      step_data.merge!(
        'job_id' => 984,
        'result' => 'passed'
      )

      subject.parse(step_data)
      expect(subject.part_result('PART3')).to eq 'Passed'
    end
  end

  describe '#parse' do
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

    it 'called on TestCaseResult instance on `job_id` part & `class_position` position' do
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
      tc1 = double('TestCase1', class_results_hash: { 'passed' => 2, 'errored' => 1 })
      tc2 = double('TestCase2', class_results_hash: { 'passed' => 3, 'failed' => 2 })
      tc3 = double('TestCase3', class_results_hash: {
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

  describe '#as_json' do
    it 'returns array of hashes for each part' do
      expect(subject).to receive(:part_as_json).and_return({}).twice
      expect(subject).to receive(:parts).and_return('P1' => [],
                                                    'P2' => [])
      expect(subject.as_json).to eq [{}, {}]
    end

    it '#part_as_json' do
      job = double('Job', id: 1, state: 'created')
      expect(subject).to receive(:parts).and_return('PART1' => []).at_least(1)
      expect(subject).to receive(:jobs_by_parts_aggregations)
        .and_return('PART1' => { 'MACHINE1' => [job] }).at_least(1)

      expect(subject.send(:part_as_json, 'PART1')).to eq(
        name: 'PART1',
        result: 'Created',
        machines: [{
          os: 'MACHINE1',
          result: 'Created',
          id: 1
        }],
        testCases: []
      )
    end
  end
end
