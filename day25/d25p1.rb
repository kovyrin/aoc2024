#! /usr/bin/env ruby

def count_matching_locks(key_pin_lengths, lock_index, checking_pin = 0)
  return 1 if checking_pin == 5
  return 0 if lock_index.empty?

  key_pin = key_pin_lengths[checking_pin]
  lock_pin_limit = 5 - key_pin # max length of the lock pin that would fit the key pin

  lock_pin_options = (0..lock_pin_limit).to_a & lock_index.keys
  lock_pin_options.sum do |lock_pin|
    count_matching_locks(key_pin_lengths, lock_index[lock_pin], checking_pin + 1)
  end
end

#------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file).map(&:strip).reject(&:empty?)

patterns = {
  lock: [],
  key: []
}

while lines.any?
  # read key pattern (5x7 characters)
  key_pattern = lines.shift(7).map(&:strip)

  # The locks are schematics where the top row is filled and the bottom is empty
  pattern_type = key_pattern.first == "#####" ? :lock : :key

  # Remove top and bottom rows to end up with a 5x5 grid
  key_pattern = key_pattern[1..-2]

  # Parse the grid into an array of pin lengths
  pin_lengths = (0..4).map { |column| key_pattern.map { |row| row[column] }.join.count("#") }

  patterns[pattern_type] << pin_lengths
end

puts "Loaded #{patterns[:key].size} keys and #{patterns[:lock].size} locks"

# Index locks by pin lengths
lock_index = Hash.new { |hash, key| hash[key] = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = Hash.new { |h3, k3| h3[k3] = Hash.new { |h4, k4| h4[k4] = Hash.new { |h5, k5| h5[k5] = false } } } } } }
patterns[:lock].each do |lock_pin_lengths|
  lock_index[lock_pin_lengths[0]][lock_pin_lengths[1]][lock_pin_lengths[2]][lock_pin_lengths[3]][lock_pin_lengths[4]] = true
end

# Now, we need to check each key to see if there are locks where it would fit (pins are shorter than the lock pins)
result = patterns[:key].sum do |key_pin_lengths|
  count_matching_locks(key_pin_lengths, lock_index)
end

puts "Keys fit count: #{result}"

# 476 - too low
# 3663 - correct
