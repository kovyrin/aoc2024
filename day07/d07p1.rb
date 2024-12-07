#! /usr/bin/env ruby

OPERATORS = [:+, :*].freeze

def valid_equation?(eq_parts, result)
  # One bit per operator in the equation, 0 is '+', 1 is '*'
  operators_count = eq_parts.size - 1
  bitmask_max = OPERATORS.size ** operators_count - 1

  0.upto(bitmask_max) do |operators_bitmask|
    # Convert the bitmask to an array of operators
    bits = operators_bitmask.to_s(OPERATORS.size).rjust(operators_count, '0').chars.map(&:to_i)
    operators = bits.map { |bit| OPERATORS[bit] }

    # Evaluate the equation with the operators
    parts = eq_parts.dup
    eq_result = parts.shift
    parts.each do |part|
      eq_result = eq_result.send(operators.shift, part)
      # Since the operators can only increase the result,
      # we can stop early if we've already exceeded the expected result value part way through
      break if eq_result > result
    end

    # Stop if we found a valid combination of operators
    return true if eq_result == result
  end

  false
end

input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file)

sum = 0
lines.each do |line|
  result, eq_parts = line.split(':').map(&:strip)
  eq_parts = eq_parts.split(' ').map(&:strip).map(&:to_i)
  result = result.to_i

  sum += result if valid_equation?(eq_parts, result)
end

puts "sum: #{sum}"

# 6855358937264 - too low
# 12839601725877 - correct
