#! /usr/bin/env ruby

#------------------------------------------------------------------------------
Point = Data.define(:x, :y) do
  def to_s
    "[#{x}, #{y}]"
  end

  def +(other)
    Point.new(x + other.x, y + other.y)
  end
end

#------------------------------------------------------------------------------
class Direction
  UP = '^'
  DOWN = 'v'
  LEFT = '<'
  RIGHT = '>'
  ALL = [UP, DOWN, LEFT, RIGHT].freeze

  STEPS = {
    UP => Point.new(0, -1),
    DOWN => Point.new(0, 1),
    LEFT => Point.new(-1, 0),
    RIGHT => Point.new(1, 0),
  }.freeze

  def self.valid?(direction)
    ALL.include?(direction)
  end

  def initialize(direction)
    @direction = direction
  end

  def inspect
    @direction.inspect
  end

  def turn_right
    new_direction = case @direction
    when UP
      RIGHT
    when RIGHT
      DOWN
    when DOWN
      LEFT
    when LEFT
      UP
    end

    self.class.new(new_direction)
  end

  def step
    STEPS[@direction]
  end
end

#------------------------------------------------------------------------------
Guard = Struct.new(:position, :direction) do
  def next_position
    position + direction.step
  end

  def take_step
    self.position = next_position
  end

  def turn_right
    self.direction = direction.turn_right
  end
end

#------------------------------------------------------------------------------
class Map
  BLOCKED = '#'.freeze

  def initialize(lines)
    @lines = lines
  end

  def width
    @lines.first.size
  end

  def height
    @lines.size
  end

  def cell(point)
    return nil if point.y < 0 || point.y >= height
    return nil if point.x < 0 || point.x >= width

    @lines[point.y][point.x]
  end

  def each_point
    0.upto(height - 1) do |y|
      0.upto(width - 1) do |x|
        yield Point.new(x, y)
      end
    end
  end

  def guard?(point)
    Direction.valid?(cell(point))
  end

  def blocked?(point)
    cell(point) == BLOCKED
  end
end

#------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file)

map = Map.new(lines)

guard = nil

map.each_point do |point|
  if map.guard?(point)
    guard_direction = Direction.new(map.cell(point))
    guard = Guard.new(point, guard_direction)
    break
  end
end

puts "Guard: #{guard}"

visited = Set.new
loop do
  visited.add(guard.position)

  new_position = guard.next_position
  if map.blocked?(new_position)
    guard.turn_right
  else
    guard.take_step
    break unless map.cell(new_position)
  end
end

puts "Visited: #{visited.size}"
