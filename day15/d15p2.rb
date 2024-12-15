#! /usr/bin/env ruby

#------------------------------------------------------------------------------
Point = Data.define(:x, :y) do
  def to_s
    "[#{x}, #{y}]"
  end

  def +(other)
    Point.new(x + other.x, y + other.y)
  end

  def distance(other)
    (x - other.x).abs + (y - other.y).abs
  end

  def vertical?
    self == Direction::UP || self == Direction::DOWN
  end
end

#------------------------------------------------------------------------------
module Direction
  UP = Point.new(0, -1)
  DOWN = Point.new(0, +1)
  LEFT = Point.new(-1, 0)
  RIGHT = Point.new(+1, 0)

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

  def move(from, to)
    object = cell(from)
    set(from, '.')
    set(to, object)
  end
end

#------------------------------------------------------------------------------
def box?(cell)
  cell == '[' || cell == ']'
end

def wall?(cell)
  cell == '#'
end

def robot?(cell)
  cell == '@'
end

def empty?(cell)
  cell == '.'
end

#------------------------------------------------------------------------------
def parts_for_object_at(map, object_coordinates)
  object_part = map.cell(object_coordinates)
  # There are no parts for empty space
  return [] if empty?(object_part)

  # The robot is a single part
  return [object_coordinates] if robot?(object_part)

  # The object is a box (left part)
  if object_part == '['
    return [object_coordinates, object_coordinates + Direction::RIGHT]
  end

  # The object is a box (right part)
  if object_part == ']'
    return [object_coordinates + Direction::LEFT, object_coordinates]
  end

  raise "Unknown object part: #{object_part} at #{object_coordinates}"
end

#------------------------------------------------------------------------------
def execute_horizontal_movement(map, object_coordinates, direction)
  neighbor_coordinates = object_coordinates + direction
  neighbor = map.cell(neighbor_coordinates)

  # Stop if we hit a wall
  return object_coordinates if wall?(neighbor)

  # If we hit a box, we need to try pushing it in the same direction
  if box?(neighbor)
    resulting_coordinates = execute_horizontal_movement(map, neighbor_coordinates, direction)
    return object_coordinates if resulting_coordinates == neighbor_coordinates # the box did not move
  end

  # The space is empty (originally or after pushing the neighbor away),
  # so we move the object to the neighbor coordinates
  map.move(object_coordinates, neighbor_coordinates)

  neighbor_coordinates
end

#------------------------------------------------------------------------------
# Check if we can move the object vertically (recursively checks each part of the object and its neighbours)
def can_move_vertically?(map, object_coordinates, direction)
  # If the cell is empty, we can move an object here
  return true if empty?(map.cell(object_coordinates))

  object_parts = parts_for_object_at(map, object_coordinates)
  neighbour_coordinates = object_parts.map { |part| part + direction }

  # If any of the neighbours are walls, we can't move the current object
  return false if neighbour_coordinates.any? { |neighbour| wall?(map.cell(neighbour)) }

  # If none of the neighbours are walls, we need to check if we can move all non-empty neighbours
  neighbour_coordinates.all? { |neighbour| can_move_vertically?(map, neighbour, direction) }
end

#------------------------------------------------------------------------------
# Moves an object identified by coordinates of one of its parts in a given direction assuming
# it is OK to perform the move (since we already checked that in can_move_vertically?)
def move_vertically(map, object_coordinates, direction)
  object_parts = parts_for_object_at(map, object_coordinates)
  neighbour_coordinates = object_parts.map { |part| part + direction }

  neighbour_coordinates.each do |neighbour|
    if box?(map.cell(neighbour))
      move_vertically(map, neighbour, direction)
    end
  end

  object_parts.each do |part|
    map.move(part, part + direction)
  end

  object_coordinates + direction
end

#------------------------------------------------------------------------------
# Safely tries to move the object identified by coordinates of one of its parts one step in a given direction
def execute_vertical_movement(map, object_coordinates, direction)
  # Check if we can move the object vertically (recursively checks each part of the object and its neighbours)
  return object_coordinates unless can_move_vertically?(map, object_coordinates, direction)

  # Perform the actual move if we know it is OK to do so
  move_vertically(map, object_coordinates, direction)
end

#------------------------------------------------------------------------------
def execute_movements(map, movements)
  # Find the robot
  robot_coordinates = nil
  map.each_point do |p|
    robot_coordinates = p if robot?(map.cell(p))
  end

  # Execute each movement in the sequence, moving the robot each time
  movements.each_char do |movement|
    direction = Direction::MOVEMENTS[movement]
    robot_coordinates = if direction.vertical?
      execute_vertical_movement(map, robot_coordinates, direction)
    else
      execute_horizontal_movement(map, robot_coordinates, direction)
    end
  end
end

#------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file)

map_size = lines.first.strip.length
map_lines = lines[0...map_size].map(&:strip)

# Render the map by replacing each cell with a cell twice as wide
# If the tile is #, the new map contains ## instead.
# If the tile is O, the new map contains [] instead.
# If the tile is ., the new map contains .. instead.
# If the tile is @, the new map contains @. instead.
rendered_map_lines = map_lines.map do |line|
  line.chars.map do |char|
    char == '#' ? '##' : char == 'O' ? '[]' : char == '.' ? '..' : char == '@' ? '@.' : char
  end.join
end

map = Map.new(rendered_map_lines)
movements = lines[map_size + 1..-1].map(&:strip).join

# Execute all the movements
execute_movements(map, movements)

# Calculate the GPS value for all boxes (using their left side to calculate the distance from the left edge)
gps_sum = 0
map.each_point do |p|
  next unless map.cell(p) == '['
  gps_sum += 100 * p.y + p.x
end

puts "GPS sum: #{gps_sum}"
