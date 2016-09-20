steps = [
  { name: 'A', position: 1, result: 'Passed', machine: 1 },
  { name: 'C', position: 2, result: 'Passed', machine: 1 },

  { name: 'B', position: 1, result: 'Passed', machine: 2 },
  { name: 'C', position: 2, result: 'Failed', machine: 2 },

  { name: 'A', position: 1, result: 'KnownBug', machine: 3 },
  { name: 'D', position: 2, result: 'Failed', machine: 3 },
  { name: 'E', position: 3, result: 'Failed', machine: 3 },
]

result = []
total_machines = steps.map { |r| r[:machine] }.max

(1..total_machines).each do |machine|
  machine_steps = steps.find_all { |s| s[:machine] == machine }.sort_by { |s| s[:position] }

  result_names = result.map { |r| r[:name] }
  machine_steps_names = machine_steps.map { |r| r[:name] }

  step_name_intersect = result_names & machine_steps_names

  if step_name_intersect.any? # there are some intersected steps so we have to deal with them
    puts step_name_intersect.inspect

    step_name_intersect.each do |intersected_step|
      # find indexes in result and current machine data
      index_of_same_step_in_result = result.find_index { |r| r[:name] == intersected_step }
      index_of_step_in_machine_results = machine_steps.find_index { |r| r[:name] == intersected_step }

      # find previous and current step in current machine data
      steps_before = machine_steps.take(index_of_step_in_machine_results)
      machine_steps = machine_steps.drop(index_of_step_in_machine_results)

      # remove and store current interseted step
      current_step = machine_steps.shift

      # update result for step with same name by current result
      result[index_of_same_step_in_result][:machines][machine.to_s] = current_step[:result]

      # format step result
      formated_results = steps_before.each_with_object([]) do |sb, res|
        res << { name: sb[:name], machines: { machine.to_s => sb[:result] } }
      end

      # include previous steps before step result
      result = result.insert(index_of_same_step_in_result, *formated_results)
    end
  end

  # append rest of the current machine data
  machine_steps.each do |ms|
    result << { name: ms[:name], machines: { machine.to_s => ms[:result] } }
  end

  puts "round #{machine} "
  puts result
  puts '-'*80
end


puts '*** RESULT ***'
puts result
