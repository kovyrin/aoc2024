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

  def modulo(width, height)
    Point.new(x % width, y % height)
  end
end

input_file = "input.txt"
lines = File.readlines(input_file)

robots = []
lines.each do |line|
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
    (robot[:p] + robot[:v] * seconds).modulo(MAP_WIDTH, MAP_HEIGHT)
  end

  # The idea here is that if the robots are spread out across the map,
  # there is no point in checking the sum of distances, since it will be high
  x_variance = robot_positions.map { |p| p.x }.uniq.length
  y_variance = robot_positions.map { |p| p.y }.uniq.length
  next if x_variance == MAP_WIDTH || y_variance == MAP_HEIGHT

  # Find the sum of distances between all robots
  # The idea here is that when they cluster together to form a christmas tree,
  # the sum of distances will be minimal
  sum_of_distances = 0
  early_exit = false

  0.upto(robot_positions.length - 1) do |i|
    (i + 1).upto(robot_positions.length - 1) do |j|
      a = robot_positions[i]
      b = robot_positions[j]

      sum_of_distances += a.distance(b)

      if sum_of_distances >= min_sum_of_distances
        early_exit = true
        break
      end
    end
    break if early_exit
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
