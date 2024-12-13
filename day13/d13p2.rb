#! /usr/bin/env ruby

require 'matrix'

OFFSET = 10_000_000_000_000

input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file).map(&:strip).reject(&:empty?)

total_tokens = 0
while lines.any?
  button_a = lines.shift
  button_b = lines.shift
  prize = lines.shift

  # Button A: X+12, Y+57
  button_a_x, button_a_y = button_a.split(":").last.strip.split(",").map { |s| s.split('+').last.to_i }
  button_b_x, button_b_y = button_b.split(":").last.strip.split(",").map { |s| s.split('+').last.to_i }

  # Prize: X=14212, Y=3815
  prize_x, prize_y = prize.split(":").last.strip.split(",").map { |s| s.split('=').last.to_i + OFFSET }

  # Create a system of equations:
  # button_a_x * x + button_b_x * y = prize_x
  # button_a_y * x + button_b_y * y = prize_y
  coefficients = Matrix[
    [button_a_x, button_b_x],
    [button_a_y, button_b_y]
  ]
  constants = Vector[prize_x, prize_y]

  # The solution is the number of presses for each button to reach the prize
  solution = coefficients.inverse * constants

  # Check if the solution is an integer (we can only press buttons an integer number of times)
  next unless solution.all? { |s| s.denominator == 1 }

  # Calculate the number of tokens (it costs 3 tokens to press button A, 1 to press button B)
  total_tokens += solution[0].to_i * 3 + solution[1].to_i
end

puts "Total tokens: #{total_tokens}"
