#! /usr/bin/env ruby

def count_arrangements(suffix: design, towels:, count_cache: {})
  return 1 if suffix.empty?
  return count_cache[suffix] if count_cache.key?(suffix)

  # Check if any of the towels match the beginning of the design
  matching_towels = towels.select { |towel| suffix.start_with?(towel) }
  return 0 if matching_towels.empty?

  result = matching_towels.sum do |towel|
    remaining_design = suffix[towel.size..]
    count_arrangements(suffix: remaining_design, towels:, count_cache:)
  end

  count_cache[suffix] = result
  result
end

input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file)

towels = lines.first.split(',').map(&:strip)
designs = lines[2..].map(&:strip)

arrangements_count = 0
designs.each do |design|
  puts "Checking design: #{design}"
  count = count_arrangements(suffix: design, towels:)

  if count > 0
    puts "  - Found #{count} possible arrangements"
    arrangements_count += count
  else
    puts "  - No possible arrangements found"
  end
end

puts
puts "Total arrangements: #{arrangements_count}"

# 848076019766013 - correct
