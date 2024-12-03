#! /usr/bin/env ruby

def clean_line(line)
  puts "Cleaning line: #{line}"
  ops = []
  line.scan(/(mul\(\d+,\d+\)|do\(\)|don't\(\))/) do |m|
    ops << m
  end
  ops.flatten
end

def execute_mul(op)
  op.gsub!('mul(', '')
  op.gsub!(')', '')
  args = op.split(',').map(&:to_i)
  args[0] * args[1]
end

def execute_ops(ops)
  enabled = true
  sum = 0
  ops.each do |op|
    case op
    when 'do()'
      puts "- enable"
      enabled = true
    when "don't()"
      puts "- disable"
      enabled = false
    else
      if enabled
        puts "- execute: #{op}"
        sum += execute_mul(op)
      else
        puts "- skip: #{op}"
      end
    end
  end
  sum
end

input_file = ENV['DEMO'] ? "input-demo-p2.txt" : "input.txt"
line = File.read(input_file)
clean_ops = clean_line(line)
puts clean_ops.inspect
sum = execute_ops(clean_ops)

puts "SUM: #{sum}"

# 95786593 - too high
# 92082041 - correct
