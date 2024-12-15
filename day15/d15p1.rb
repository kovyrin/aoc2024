#! /usr/bin/env ruby

#------------------------------------------------------------------------------
Point = Data.define(:x, :y) do
  def to_s
    "[#{x}, #{y}]"
  end

  def +(other)
    Point.new(x + other.x, y + other.y)
  end

  def -(other)
    Point.new(x - other.x, y - other.y)
  end

  def distance(other)
    (x - other.x).abs + (y - other.y).abs
  end

  def vector(other)
    Point.new(other.x - x, other.y - y)
  end
end

#------------------------------------------------------------------------------
module Direction
  UP = Point.new(0, -1)
  DOWN = Point.new(0, +1)
  LEFT = Point.new(-1, 0)
  RIGHT = Point.new(+1, 0)

  ALL = [UP, DOWN, LEFT, RIGHT]

  MOVEMENTS = {
    '>' => RIGHT,
    '<' => LEFT,
    '^' => UP,
    'v' => DOWN
  }
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

  def to_s
    @lines.join("\n")
  end

  def inspect
    result = <<~MAP
      Map #{width}x#{height}:
      #{to_s}
    MAP
    result
  end
end

#------------------------------------------------------------------------------
def execute_movement(map, object_coordinates, direction)
  object_cell = map.cell(object_coordinates)
  # puts "Executing movement #{direction} at #{object_coordinates} for object #{object_cell}"

  neighbor_coordinates = object_coordinates + direction
  neighbor_cell = map.cell(neighbor_coordinates)
  # puts "Neighbor coordinates: #{neighbor_coordinates}, neighbor cell: #{neighbor_cell}"

  # Stop if we hit a wall
  if neighbor_cell == '#'
    # puts "The neighbor is a wall, can't move"
    return object_coordinates
  end

  # If we hit an object, we need to try pushing the object in the same direction
  if neighbor_cell == 'O'
    # puts "The neighbor is an object, trying to push it"
    resulting_coordinates = execute_movement(map, neighbor_coordinates, direction)
    if resulting_coordinates == neighbor_coordinates # the object did not move
      # puts "The object did not move, can't push it, so our position is unchanged"
      return object_coordinates
    end
  end

  # The space is empty (originally or after pushing the neighbor away),
  # so we move the object to the neighbor coordinates
  map.set(object_coordinates, '.')
  map.set(neighbor_coordinates, object_cell)
  neighbor_coordinates
end

#------------------------------------------------------------------------------
def execute_movements(map, robot_coordinates, movements)
  movements.each_char do |movement|
    direction = Direction::MOVEMENTS[movement]
    robot_coordinates = execute_movement(map, robot_coordinates, direction)
  end
end

#------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file)

map_size = lines.first.strip.length
map_lines = lines[0..map_size - 1].map(&:strip)
map = Map.new(map_lines)
movements = lines[map_size + 1..-1].map(&:strip).join

robot_coordinates = nil
map.each_point do |p|
  robot_coordinates = p if map.cell(p) == '@'
end

execute_movements(map, robot_coordinates, movements)

gps_sum = 0
map.each_point do |p|
  next unless map.cell(p) == 'O'
  gps = 100 * p.y + p.x
  gps_sum += gps
end

puts "GPS sum: #{gps_sum}"

# 1413675 - Correct
