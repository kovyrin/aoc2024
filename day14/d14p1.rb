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

input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file)

robots = []
lines.each do |line|
  # p=0,4 v=3,-3
  p, v = line.split(' ').map { |s| s.split('=').last.split(',').map(&:to_i) }

  p = Point.new(p[0], p[1])
  v = Point.new(v[0], v[1])

  robots << { p:, v: }
end

STEPS = 100
MAP_WIDTH = ENV['REAL'] ? 101 : 11
MAP_HEIGHT = ENV['REAL'] ? 103 : 7

final_positions = robots.map do |robot|
  # Simulate the robots moving for STEPS steps
  pos = robot[:p] + robot[:v] * STEPS
  # Wrap around the map (negative coordinates wrap to the end of the map)
  pos.x = pos.x % MAP_WIDTH
  pos.y = pos.y % MAP_HEIGHT
  pos
end

QUADRANT_WIDTH = MAP_WIDTH / 2
QUADRANT_HEIGHT = MAP_HEIGHT / 2

safety_factor = 1

# count robots in each quadrant, skipping the middle column and row
[0, 1].each do |qx|
  [0, 1].each do |qy|
    x_range_start = qx * QUADRANT_WIDTH + qx
    x_range_end = x_range_start + QUADRANT_WIDTH - 1
    y_range_start = qy * QUADRANT_HEIGHT + qy
    y_range_end = y_range_start + QUADRANT_HEIGHT - 1

    x_range = (x_range_start..x_range_end)
    y_range = (y_range_start..y_range_end)

    robot_count = final_positions.count { |p| x_range.include?(p.x) && y_range.include?(p.y) }

    safety_factor *= robot_count
  end
end

puts "Safety factor: #{safety_factor}"

# 230435667 - correct
