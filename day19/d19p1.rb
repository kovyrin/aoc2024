#! /usr/bin/env ruby

def possible_design?(design, towels_by_start)
  return true if design.empty?

  potential_towels = towels_by_start.fetch(design[0], [])

  # Check if any of the potential towels match the beginning of the design
  matching_towels = potential_towels.select { |towel| design.start_with?(towel) }
  return false if matching_towels.empty?

  matching_towels.any? do |towel|
    remaining_design = design[towel.size..]
    possible_design?(remaining_design, towels_by_start)
  end
end

input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file)

towels = lines.first.split(',').map(&:strip)
designs = lines[2..].map(&:strip)
towels_by_start = towels.group_by { |t| t[0] }

possible_designs = []
designs.each do |design|
  possible_designs << design if possible_design?(design, towels_by_start)
end

puts "Possible designs: #{possible_designs.inspect}"
puts
puts "Possible designs count: #{possible_designs.size}"
