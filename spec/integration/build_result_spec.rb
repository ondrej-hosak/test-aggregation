
require 'test_aggregation'

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

    describe 'added steps' do
      describe 'cyclic example' do
        it 'maps results correctly' do
        end
      end
      describe 'non-cyclic example' do
        let(:machine1_job) do
          double('Job', id: 982, part_method: 'PART1', machine_method: 'MACHINE1', state: 'passed')
        end
        let(:machine2_job) do
          double('Job', id: 983, part_method: 'PART1', machine_method: 'MACHINE2', state: 'passed')
        end
        let(:machine3_job) do
          double('Job', id: 984, part_method: 'PART1', machine_method: 'MACHINE3', state: 'passed')
        end

        let(:add_build) do
          double('Add build', matrix: [machine1_job, machine2_job, machine3_job])
        end

        let(:test1_data) do
          {
            input: [
              #definition of static steps for 982
              {
                'job_id'          => 982,
                'name'            => 'passed step',
                'position'        => 1,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'created',
                'number'          => 0
              },
              {
                'job_id'          => 982,
                'name'            => 'step adding another steps dynamically',
                'position'        => 2,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'created',
                'number'          => 0
              },
              {
                'job_id'          => 982,
                'name'            => 'step adding another steps dynamically',
                'position'        => 1,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'created',
                'number'          => 0
              },
              {
                'job_id'          => 982,
                'name'            => 'failed step',
                'position'        => 2,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'created',
                'number'          => 0
              },
              #definition of static steps for 983
              {
                'job_id'          => 983,
                'name'            => 'passed step',
                'position'        => 1,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'created',
                'number'          => 0
              },
              {
                'job_id'          => 983,
                'name'            => 'step adding another steps dynamically',
                'position'        => 2,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'created',
                'number'          => 0
              },
              {
                'job_id'          => 983,
                'name'            => 'step adding another steps dynamically',
                'position'        => 1,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'created',
                'number'          => 0
              },
              {
                'job_id'          => 983,
                'name'            => 'failed step',
                'position'        => 2,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'created',
                'number'          => 0
              },
              #definition of static steps for 984
              {
                'job_id'          => 984,
                'name'            => 'passed step',
                'position'        => 1,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'created',
                'number'          => 0
              },
              {
                'job_id'          => 984,
                'name'            => 'step adding another steps dynamically',
                'position'        => 2,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'created',
                'number'          => 0
              },
              {
                'job_id'          => 984,
                'name'            => 'step adding another steps dynamically',
                'position'        => 1,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'created',
                'number'          => 0
              },
              {
                'job_id'          => 984,
                'name'            => 'failed step',
                'position'        => 2,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'created',
              },
              #setting up statuses of 982
              {
                'job_id'          => 982,
                'name'            => 'passed step',
                'position'        => 1,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'passed',
                'number'          => 1
              },
              {
                'job_id'          => 982,
                'name'            => 'step adding another steps dynamically',
                'position'        => 2,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'passed',
                'number'          => 1
              },
              {
                'job_id'          => 982,
                'name'            => 'step adding another steps dynamically',
                'position'        => 1,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'passed',
                'number'          => 1
              },
              {
                'job_id'          => 982,
                'name'            => 'failed step',
                'position'        => 2,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'passed',
                'number'          => 1
              },
              # Dynamically added steps follow
              # 982
              {
                'job_id'          => 982,
                'name'            => 'dynamic shared step 1 for test case A',
                'uuid'            => '982A0000-4741-4D9A-9476-88A125619525',
                'position'        => 3,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'created',
                'number'          => 0,
                'added_step'      => true
              },
              {
                'job_id'          => 982,
                'name'            => 'dynamic step 2 for test case A for 982',
                'uuid'            => '982A0001-4741-4D9A-9476-88A125619525',
                'position'        => 4,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'created',
                'number'          => 0,
                'added_step'      => true
              },
              {
                'job_id'          => 982,
                'name'            => 'dynamic shared step 1 for test case A',
                'uuid'            => '982A0000-4741-4D9A-9476-88A125619525',
                'position'        => 3,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'passed',
                'number'          => 1,
                'added_step'      => true
              },
              {
                'job_id'          => 982,
                'name'            => 'dynamic step 2 for test case A for 982',
                'uuid'            => '982A0001-4741-4D9A-9476-88A125619525',
                'position'        => 4,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'passed',
                'number'          => 1,
                'added_step'      => true
              },
              {
                'job_id'          => 982,
                'name'            => 'dynamic shared step 1 for test case B',
                'uuid'            => '982B0000-4741-4D9A-9476-88A125619525',
                'position'        => 3,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'created',
                'number'          => 0,
                'added_step'      => true
              },
              {
                'job_id'          => 982,
                'name'            => 'dynamic step 2 for test case B for 982',
                'uuid'            => '982B0001-4741-4D9A-9476-88A125619525',
                'position'        => 4,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'created',
                'number'          => 0,
                'added_step'      => true
              },
              {
                'job_id'          => 982,
                'name'            => 'dynamic shared step 1 for test case B',
                'uuid'            => '982B0000-4741-4D9A-9476-88A125619525',
                'position'        => 3,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'passed',
                'number'          => 1,
                'added_step'      => true
              },
              {
                'job_id'          => 982,
                'name'            => 'dynamic step 2 for test case B for 982',
                'uuid'            => '982B0001-4741-4D9A-9476-88A125619525',
                'position'        => 4,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'passed',
                'number'          => 1,
                'added_step'      => true
              },
              # 983
              {
                'job_id'          => 983,
                'name'            => 'dynamic shared step 1 for test case A',
                'uuid'            => '983A0000-4741-4D9A-9476-88A125619525',
                'position'        => 3,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'created',
                'number'          => 0,
                'added_step'      => true
              },
              {
                'job_id'          => 983,
                'name'            => 'dynamic step 2 for test case A for 983',
                'uuid'            => '983A0001-4741-4D9A-9476-88A125619525',
                'position'        => 4,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'created',
                'number'          => 0,
                'added_step'      => true
              },
              {
                'job_id'          => 983,
                'name'            => 'dynamic shared step 1 for test case A',
                'uuid'            => '983A0000-4741-4D9A-9476-88A125619525',
                'position'        => 3,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'passed',
                'number'          => 1,
                'added_step'      => true
              },
              {
                'job_id'          => 983,
                'name'            => 'dynamic step 2 for test case A for 983',
                'uuid'            => '983A0001-4741-4D9A-9476-88A125619525',
                'position'        => 4,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'passed',
                'number'          => 1,
                'added_step'      => true
              },
              {
                'job_id'          => 983,
                'name'            => 'dynamic shared step 1 for test case B',
                'uuid'            => '983B0000-4741-4D9A-9476-88A125619525',
                'position'        => 3,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'created',
                'number'          => 0,
                'added_step'      => true
              },
              {
                'job_id'          => 983,
                'name'            => 'dynamic step 2 for test case B for 983',
                'uuid'            => '983B0001-4741-4D9A-9476-88A125619525',
                'position'        => 4,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'created',
                'number'          => 0,
                'added_step'      => true
              },
              {
                'job_id'          => 983,
                'name'            => 'dynamic step 2 for test case B for 983,984',
                'uuid'            => '984B0001-4741-4D9A-9476-88A125619525',
                'position'        => 5,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'created',
                'number'          => 0,
                'added_step'      => true
              },
              {
                'job_id'          => 983,
                'name'            => 'dynamic shared step 1 for test case B',
                'uuid'            => '983B0000-4741-4D9A-9476-88A125619525',
                'position'        => 3,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'passed',
                'number'          => 1,
                'added_step'      => true
              },
              {
                'job_id'          => 983,
                'name'            => 'dynamic step 2 for test case B for 983',
                'uuid'            => '983B0001-4741-4D9A-9476-88A125619525',
                'position'        => 4,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'passed',
                'number'          => 1,
                'added_step'      => true
              },
              {
                'job_id'          => 983,
                'name'            => 'dynamic step 2 for test case B for 983,984',
                'uuid'            => '984B0001-4741-4D9A-9476-88A125619525',
                'position'        => 5,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'failed',
                'number'          => 1,
                'added_step'      => true
              },
              # 984
              {
                'job_id'          => 984,
                'name'            => 'dynamic shared step 1 for test case A',
                'uuid'            => '984A0000-4741-4D9A-9476-88A125619525',
                'position'        => 3,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'created',
                'number'          => 0,
                'added_step'      => true
              },
              {
                'job_id'          => 984,
                'name'            => 'dynamic step 2 for test case A for 984',
                'uuid'            => '984A0001-4741-4D9A-9476-88A125619525',
                'position'        => 4,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'created',
                'number'          => 0,
                'added_step'      => true
              },
              {
                'job_id'          => 984,
                'name'            => 'dynamic shared step 1 for test case A',
                'uuid'            => '984A0000-4741-4D9A-9476-88A125619525',
                'position'        => 3,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'passed',
                'number'          => 1,
                'added_step'      => true
              },
              {
                'job_id'          => 984,
                'name'            => 'dynamic step 2 for test case A for 984',
                'uuid'            => '984A0001-4741-4D9A-9476-88A125619525',
                'position'        => 4,
                'class_name'      => 'A',
                'class_position'  => 1,
                'result'          => 'passed',
                'number'          => 1,
                'added_step'      => true
              },
              {
                'job_id'          => 984,
                'name'            => 'dynamic shared step 1 for test case B',
                'uuid'            => '984B0000-4741-4D9A-9476-88A125619525',
                'position'        => 3,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'created',
                'number'          => 0,
                'added_step'      => true
              },
              {
                'job_id'          => 984,
                'name'            => 'dynamic step 2 for test case B for 983,984',
                'uuid'            => '984B0001-4741-4D9A-9476-88A125619525',
                'position'        => 4,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'created',
                'number'          => 0,
                'added_step'      => true
              },
              {
                'job_id'          => 984,
                'name'            => 'dynamic shared step 1 for test case B',
                'uuid'            => '984B0000-4741-4D9A-9476-88A125619525',
                'position'        => 3,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'passed',
                'number'          => 1,
                'added_step'      => true
              },
              {
                'job_id'          => 984,
                'name'            => 'dynamic step 2 for test case B for 983,984',
                'uuid'            => '984B0001-4741-4D9A-9476-88A125619525',
                'position'        => 4,
                'class_name'      => 'B',
                'class_position'  => 2,
                'result'          => 'failed',
                'number'          => 1,
                'added_step'      => true
              }
            ]
          }
        end
        let(:subject2) do
          TestAggregation::BuildResults.new(
            add_build,
            ->(job) { job.part_method },
            ->(job) { job.machine_method },
            -> (test_step) { test_step[:result] }
          )
        end
        let(:sample) { subject2.as_json }

        before :each do
          test1_data[:input].each { |input|
            #input.metge!({ 'uuid' => Secu})
            #pp "adding: #{input}"
            subject2.parse(input)
          }
        end

        describe 'testCase A' do
          it 'has passed results for all machines in dynamicly added step 1' do
            expect(machine_result(2, 'MACHINE1')).to eq 'passed'
            expect(machine_result(2, 'MACHINE2')).to eq 'passed'
            expect(machine_result(2, 'MACHINE3')).to eq 'passed'
          end

          it 'has passed for MACHINE1 and pending results for other machines in dynamically added step 2(982)' do
            expect(machine_result(3, 'MACHINE1')).to eq 'passed'
            expect(machine_result(3, 'MACHINE2')).to eq 'pending'
            expect(machine_result(3, 'MACHINE3')).to eq 'pending'
          end

          it 'has passed for MACHINE3 and pending results for other machines in dynamically added step 2(983)' do
            expect(machine_result(3, 'MACHINE1')).to eq 'passed'
            expect(machine_result(3, 'MACHINE2')).to eq 'pending'
            expect(machine_result(3, 'MACHINE3')).to eq 'pending'
          end

          def machine_result(test_step_position, machine_name)
            sample.first[:testCases].first[:testSteps][test_step_position][:machines][machine_name][:result]
          end
        end

        describe 'testCase B' do
          it 'has 2x failed for 983 and 984, pending for 982 in dynamically added step 2' do
            expect(machine_result(5, 'MACHINE1')).to eq 'pending'
            expect(machine_result(5, 'MACHINE2')).to eq 'failed'
            expect(machine_result(5, 'MACHINE3')).to eq 'failed'
          end

          def machine_result(test_step_position, machine_name)
            sample.first[:testCases].last[:testSteps][test_step_position][:machines][machine_name][:result]
          end
        end
      end
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
