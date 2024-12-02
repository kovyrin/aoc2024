#! /usr/bin/env ruby

# Checks if all increasing
def safe?(report)
  report.each_cons(2) do |a, b|
    return false if a >= b
    return false if b - a > 3
  end

  return true
end

def safe_with_dampener?(report)
  0.upto(report.size - 1) do |i|
    dampened = report.clone
    dampened.delete_at(i)
    return true if safe?(dampened)
  end

  return false
end


input_file = ENV['DEMO'] ? "input-demo.txt" : "input.txt"
reports = File.readlines(input_file).map do |line|
  line.split.map(&:to_i)
end

safe_reports = reports.select { |l| safe_with_dampener?(l) || safe_with_dampener?(l.reverse) }.count
puts "Safe: #{safe_reports}"
