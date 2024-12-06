#! /usr/bin/env ruby

#------------------------------------------------------------------------------
Point = Data.define(:x, :y) do
  def to_s
    "#{x},#{y}"
  end

  def inspect
    to_s
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

  def to_s
    @direction
  end

  def inspect
    to_s.inspect
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
Guard = Data.define(:position, :direction) do
  def next_position
    position + direction.step
  end

  def take_step
    self.class.new(next_position, direction)
  end

  def turn_right
    self.class.new(position, direction.turn_right)
  end

  def inspect
    "(#{position}: #{direction})"
  end

  def state
    "#{position.x}:#{position.y}:#{direction}"
  end
end

#------------------------------------------------------------------------------
class Map
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

  def set(point, value)
    return nil if point.y < 0 || point.y >= height
    return nil if point.x < 0 || point.x >= width

    @lines[point.y][point.x] = value
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
    state = cell(point)
    state && state != '.'
  end
end

#------------------------------------------------------------------------------
def walk_once(map, guard)
  visited = Set.new

  loop do
    if map.blocked?(guard.next_position)
      guard = guard.turn_right
    else
      guard = guard.take_step
      break unless map.cell(guard.position)
      visited.add(guard.position)
    end
  end

  visited
end

#------------------------------------------------------------------------------
def has_a_loop?(map, guard)
  seen_states = Set.new

  loop do
    if map.blocked?(guard.next_position)
      guard = guard.turn_right
    else
      guard = guard.take_step
      return false unless map.cell(guard.position)

      state = guard.state
      return true if seen_states.include?(state)

      seen_states.add(state)
    end
  end
end

#------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file).map(&:strip).reject(&:empty?)

map = Map.new(lines)
puts "Map size: #{map.width}x#{map.height}"
guard = nil

map.each_point do |point|
  if map.guard?(point)
    guard_direction = Direction.new(map.cell(point))
    guard = Guard.new(point, guard_direction)
    map.set(point, '.')
    break
  end
end

# initial pass
path_points = walk_once(map, guard)

blocks_with_loops = Set.new
checked_points = 0
path_points.each do |point|
  checked_points += 1
  puts "Progress: #{checked_points}/#{path_points.size}"

  map.set(point, 'O')
  blocks_with_loops.add(point.inspect) if has_a_loop?(map, guard)
  map.set(point, '.')
end

puts "Blocks with loops: #{blocks_with_loops.size}"

# 1916 - too high
# 1915 - too high
# 1721 - correct!
