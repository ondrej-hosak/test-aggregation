describe TestAggregation::StepResult do
  let(:job) { double('Job', id: 1, machine: 'MACHINE1') }
  let(:build_result) do
    res = double('BuildResult')
    allow(res).to receive(:aggregate_by) { |x| x.machine }
    allow(res).to receive(:step_result_constructor) do |step_result|
      {
        description: step_result.name,
        results: step_result.results
      }
    end
    res
  end
  let(:test_class) do
    double('TestClass',
           find_job: job,
           build_result: build_result,
           step_result_callback: ->(step) { step['result'] }
          )
  end
  let(:subject)    { TestAggregation::StepResult.new(test_class) }

  describe '#parse' do
    it 'raise exception when name does not match' do
      subject.parse('name' => 'NAME1', 'result' => 'custom-result')
      expect do
        subject.parse('name' => 'ANOTHER-NAME', 'result' => 'custom-result')
      end.to raise_error(/Step name mishmas/)
    end

    it 'skip input when number is lower then the last one' do
      uuid = SecureRandom.uuid
      subject.parse(
        'name' => 'NAME1',
        'result' => 'custom-result',
        'number' => 2,
        'uuid' => uuid
      )
      subject.parse(
        'name' => 'NAME1',
        'result' => 'failed',
        'number' => 1,
        'uuid' => uuid
      )
      expect(subject.results['MACHINE1']).to eq(result: 'custom-result')
    end

    it 'saves `name` of the step' do
      subject.parse('name' => 'NAME1', 'result' => 'custom-result')
      expect(subject.name).to eq 'NAME1'
    end

    it 'saves `result` of the step by calling callback `aggregate_by`' do
      job1 = double('Job', id: 1, machine: 'XP')
      job2 = double('Job', id: 2, machine: '7x64')
      job3 = double('Job', id: 3, machine: '8x64')
      allow(build_result).to receive(:aggregate_by) { |x| 'custom-' + x.machine }
      expect(test_class).to receive(:find_job).and_return(job1, job2, job3)
      subject.parse('name' => 'NAME1', 'result' => 'created', 'number' => 1)
      subject.parse('name' => 'NAME1', 'result' => 'failed', 'number' => 1)
      subject.parse('name' => 'NAME1', 'result' => 'passed', 'number' => 1)
      expect(subject.results).to eq('custom-XP' => { result: 'created' },
                                    'custom-7x64' => { result: 'failed' },
                                    'custom-8x64' => { result: 'passed' })
    end
  end

  describe '#as_json' do
    it 'returns a Hash' do
      expect(subject.as_json).to be_kind_of(Hash)
    end

    it 'get aggregated results by callback' do
      expect(build_result).to receive(:step_result_constructor) { |j|
        { res: j }
      }
      step = subject.parse('name' => 'NAME1', 'result' => 'custom-result')
      expect(subject.as_json).to eq(res: step)
    end
  end

  describe '#results_hash' do
    let(:job1) { double('Job', id: 1, machine: 'XP') }
    let(:job2) { double('Job', id: 2, machine: '7x64') }
    let(:job3) { double('Job', id: 3, machine: '8x64') }
    let(:job4) { double('Job', id: 4, machine: '2000') }

    before(:each) do
      expect(test_class).to receive(:find_job).and_return(job1, job2, job3, job4)
      subject.parse('name' => 'NAME1', 'result' => 'created', 'number' => 1)
      subject.parse('name' => 'NAME1', 'result' => 'failed', 'number' => 1)
      subject.parse('name' => 'NAME1', 'result' => 'passed', 'number' => 1)
      subject.parse('name' => 'NAME1', 'result' => 'passed', 'number' => 1)
    end
    it 'counts particular results' do
      expect(subject.results_hash).to eq('created' => 1,
                                         'failed' => 1,
                                         'passed' => 2)
    end

    it 'filter result counts by machine name' do
      expect(subject.results_hash(machine: '8x64')).to eq('passed' => 1)
    end
  end
end
