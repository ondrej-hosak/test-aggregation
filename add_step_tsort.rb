require 'tsort'

def steps
  [
    { name: 'A', position: 1, result: 'Passed', machine: 1 },
    { name: 'C', position: 2, result: 'Passed', machine: 1 },

    { name: 'B', position: 1, result: 'Passed', machine: 2 },
    { name: 'C', position: 2, result: 'Failed', machine: 2 },

    { name: 'A', position: 1, result: 'KnownBug', machine: 3 },
    { name: 'D', position: 2, result: 'Failed', machine: 3 },
    { name: 'E', position: 3, result: 'Failed', machine: 3 },
  ]
end

## DATA PREPROCESSING
preprocessed_steps = {}
total_machines = steps.map { |r| r[:machine] }.max

(1..total_machines).each do |machine|
  machine_steps = steps.find_all { |s| s[:machine] == machine }.sort_by { |s| s[:position] }

  machine_steps.each_with_index do |ms, i|
    preprocessed_steps[ms[:name]] ||= []
    machine_steps.take(i).map { |s| s[:name] }.each { |name| preprocessed_steps[ms[:name]] << name }
  end

  preprocessed_steps.each { |_key, value| value.uniq! }
end

def get_result_from_machine(machine, name)
  step_result = steps.find { |s| s[:machine] == machine && s[:name] == name }
  puts step_result
  step_result ? step_result[:result] : 'NotPerformed'
end

# EXTEND HASH BY TSORT
class Hash
  include TSort

  alias tsort_each_node each_key

  def tsort_each_child(node, &block)
    fetch(node).each(&block)
  end
end

## MAIN
begin
  sorted = preprocessed_steps.tsort

  p sorted

  all_results = sorted.each_with_object([]) do |s, result|
    machines_result = (1..total_machines).each_with_object({}) { |machine, res| res[machine.to_s] = get_result_from_machine(machine, s) }

    result << {
      name: s,
      machines: machines_result
    }
  end

  puts '-'*80
  puts '*** RESULT ***'
  puts all_results

rescue TSort::Cyclic => e
  puts "\ncycle detected: #{e}"
end
