#! /usr/bin/env ruby

CONCAT_OPERATOR = :|
OPERATORS = [CONCAT_OPERATOR, :+, :*].freeze

def generate_operators(operators_count)
  OPERATORS.repeated_permutation(operators_count)
end

def valid_equation?(eq_parts, result)
  puts "eq_parts: #{eq_parts.inspect}"
  operators_count = eq_parts.size - 1

  generate_operators(operators_count).each do |operators|
    # Evaluate the equation with the operators
    parts = eq_parts.dup
    eq_result = parts.shift
    parts.each do |part|
      operator = operators.shift
      eq_result = if operator == CONCAT_OPERATOR
        (eq_result.to_s + part.to_s).to_i
      else
        eq_result.send(operator, part)
      end

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
