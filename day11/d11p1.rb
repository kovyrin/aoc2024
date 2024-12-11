#! /usr/bin/env ruby

def blink(stones)
  output = []

  stones.each do |stone|
    if stone == 0
      output << 1
    elsif (string_stone = stone.to_s).size.even?
      s1 = string_stone[0..string_stone.size/2-1]
      s2 = string_stone[string_stone.size/2..string_stone.size]
      output << s1.to_i
      output << s2.to_i
    else
      output << stone * 2024
    end
  end

  output
end

input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
stones = File.readlines(input_file).first.split.map(&:to_i)

25.times do |i|
  stones = blink(stones)
  puts "After #{i + 1} blinks:"
  puts "Number of stones: #{stones.size}"
  puts
end

# 213625 - correct
