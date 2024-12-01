#!/usr/bin/env ruby

input = File.readlines("input.txt")

left = []
right = []

input.each do |line|
  left << line.split[0].to_i
  right << line.split[1].to_i
end

left.sort!
right.sort!

total_distance = 0

0.upto(left.size - 1) do |i|
  total_distance += (left[i] - right[i]).abs
end

puts total_distance
