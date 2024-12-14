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

10000.times do |seconds|
  robot_positions = robots.map do |robot|
    pos = robot[:p] + robot[:v] * seconds
    pos.x = pos.x % MAP_WIDTH
    pos.y = pos.y % MAP_HEIGHT
    pos
  end

  # Check if the majority of robots are clumped together, displaying a christmas tree
  x_variance = robot_positions.map(&:x).sort.uniq.count
  y_variance = robot_positions.map(&:y).sort.uniq.count

  # Extra-shady: just show the map and let the user look at it until they see the tree 🫠
  if x_variance < 96 && y_variance < 90
    system('clear')
    puts "#{seconds}: vx=#{x_variance}, vy=#{y_variance}"
    draw_map(robot_positions)
    gets
  end
end

# 7709 - correct
