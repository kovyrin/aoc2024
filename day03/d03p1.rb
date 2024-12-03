#! /usr/bin/env ruby

def clean_line(line)
  puts "Cleaning line: #{line}"
  ops = []
  line.scan(/mul\(\d+,\d+\)/) do |m|
    ops << m
  end
  ops
end

def execute_op(op)
  op.gsub!('mul(', '')
  op.gsub!(')', '')
  args = op.split(',').map(&:to_i)
  args[0] * args[1]
end

def execute_ops(ops)
  ops.sum { |op| execute_op(op) }
end

input_file = ENV['DEMO'] ? "input-demo.txt" : "input.txt"
lines = File.readlines(input_file)

sum = 0
lines.each do |line|
  clean_ops = clean_line(line)
  result = execute_ops(clean_ops)
  sum += result
end

puts "SUM: #{sum}"
