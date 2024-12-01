#!/usr/bin/env ruby

input = File.readlines("input.txt")

left = []
right = Hash.new(0)

input.each do |line|
  left << line.split[0].to_i
  right[line.split[1].to_i] += 1
end

similarity_score = 0

left.each do |l|
  similarity_score += l * right[l]
end

puts similarity_score
