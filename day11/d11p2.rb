#! /usr/bin/env ruby

def blink(stones)
  output = Hash.new(0)

  stones.each do |stone, count|
    if stone == 0
      output[1] += count
    elsif (string_stone = stone.to_s).size.even?
      s1 = string_stone[0..string_stone.size/2-1]
      s2 = string_stone[string_stone.size/2..string_stone.size]
      output[s1.to_i] += count
      output[s2.to_i] += count
    else
      output[stone * 2024] += count
    end
  end

  output
end

input_file = "input.txt"
stones = File.readlines(input_file).first.split.map(&:to_i)

stones = stones.inject({}) { |acc, stone| acc[stone] = 1; acc }

75.times do |i|
  stones = blink(stones)
  puts "After #{i + 1} blinks:"
  puts "Number of stones: #{stones.values.sum}"
  puts
end

puts stones.values.sum
