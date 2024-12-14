#! /usr/bin/env ruby

Point = Struct.new(:x, :y) do
  def to_s
    "[#{x}, #{y}]"
  end

  def +(other)
    Point.new(x + other.x, y + other.y)
  end

  def -(other)
    Point.new(x - other.x, y - other.y)
  end

  def *(scalar)
    Point.new(x * scalar, y * scalar)
  end

  def distance(other)
    (x - other.x).abs + (y - other.y).abs
  end

  def vector(other)
    Point.new(other.x - x, other.y - y)
  end
end

def draw_map(robot_positions)
  0.upto(MAP_HEIGHT) do |row|
    0.upto(MAP_WIDTH) do |col|
      if robot_positions.include?(Point.new(col, row))
        STDOUT.write('#')
      else
        STDOUT.write('.')
      end
    end
    puts
  end
  puts
end

input_file = "input.txt"
lines = File.readlines(input_file)

robots = []
lines.each do |line|
  # p=0,4 v=3,-3
  p, v = line.split(' ').map { |s| s.split('=').last.split(',').map(&:to_i) }

  p = Point.new(p[0], p[1])
  v = Point.new(v[0], v[1])

  robots << { p:, v: }
end

MAP_WIDTH = 101
MAP_HEIGHT = 103

min_sum_of_distances = Float::INFINITY
min_sum_of_distances_seconds = 0

(MAP_WIDTH * MAP_HEIGHT).times do |seconds|
  robot_positions = robots.map do |robot|
    pos = robot[:p] + robot[:v] * seconds
    pos.x = pos.x % MAP_WIDTH
    pos.y = pos.y % MAP_HEIGHT
    pos
  end

  # Find the sum of distances between all robots
  # The idea here is that when they cluster together to form a christmas tree,
  # the sum of distances will be minimal
  sum_of_distances = 0
  early_exit = false
  robot_positions.combination(2).each do |a, b|
    sum_of_distances += a.distance(b)
    if sum_of_distances >= min_sum_of_distances
      early_exit = true
      break
    end
  end

  next if early_exit

  if sum_of_distances < min_sum_of_distances
    min_sum_of_distances = sum_of_distances
    min_sum_of_distances_seconds = seconds
    puts "New minimum sum of distances: #{min_sum_of_distances} at #{min_sum_of_distances_seconds} seconds"
  end
end

puts "Minimum sum of distances: #{min_sum_of_distances} at #{min_sum_of_distances_seconds} seconds"

# 7709 - correct
