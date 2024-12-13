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
module Direction
  UP = Point.new(0, -1)
  DOWN = Point.new(0, +1)
  LEFT = Point.new(-1, 0)
  RIGHT = Point.new(+1, 0)

  ALL = [UP, DOWN, LEFT, RIGHT]
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
# Returns the number of different corners for the given 1x1 square on the map
def number_of_corners(region, map, point)
  corners = 0
  corners += 1 if external_top_right?(region, map, point)
  corners += 1 if external_bottom_right?(region, map, point)
  corners += 1 if external_bottom_left?(region, map, point)
  corners += 1 if external_top_left?(region, map, point)

  corners += 1 if internal_top_right?(region, map, point)
  corners += 1 if internal_bottom_right?(region, map, point)
  corners += 1 if internal_bottom_left?(region, map, point)
  corners += 1 if internal_top_left?(region, map, point)

  corners
end

def external_top_right?(region, map, point)
  map.cell(point + Direction::UP) != region &&
    map.cell(point + Direction::RIGHT) != region
end

def external_bottom_right?(region, map, point)
  map.cell(point + Direction::DOWN) != region &&
    map.cell(point + Direction::RIGHT) != region
end

def external_bottom_left?(region, map, point)
  map.cell(point + Direction::DOWN) != region &&
    map.cell(point + Direction::LEFT) != region
end

def external_top_left?(region, map, point)
  map.cell(point + Direction::UP) != region &&
    map.cell(point + Direction::LEFT) != region
end

# AAx
# BBA
# BBA
def internal_top_right?(region, map, point)
  map.cell(point + Direction::DOWN) == region &&
    map.cell(point + Direction::LEFT) == region &&
    map.cell(point + Direction::DOWN + Direction::LEFT) != region
end

# ABB
# ABB
# xAA
def internal_bottom_left?(region, map, point)
  map.cell(point + Direction::UP) == region &&
    map.cell(point + Direction::RIGHT) == region &&
    map.cell(point + Direction::UP + Direction::RIGHT) != region
end

# BBA
# BBA
# AAx
def internal_bottom_right?(region, map, point)
  map.cell(point + Direction::UP) == region &&
    map.cell(point + Direction::LEFT) == region &&
    map.cell(point + Direction::UP + Direction::LEFT) != region
end

# xAA
# ABB
# ABB
def internal_top_left?(region, map, point)
  map.cell(point + Direction::DOWN) == region &&
    map.cell(point + Direction::RIGHT) == region &&
    map.cell(point + Direction::DOWN + Direction::RIGHT) != region
end

#------------------------------------------------------------------------------
def measure_region(region, map, point, visited)
  return 0, 0 if visited.include?(point)
  point_plant = map.cell(point)
  return 0, 0 if point_plant != region
  visited.add(point)

  area = 1
  corners = number_of_corners(region, map, point)

  Direction::ALL.each do |dir|
    neighbor = point + dir
    neighbor_plant = map.cell(neighbor)

    if neighbor_plant == region
      neighbor_area, neighbor_corners = measure_region(region, map, neighbor, visited)
      area += neighbor_area
      corners += neighbor_corners
    end
  end

  [area, corners]
end

#------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file).map(&:strip).reject(&:empty?)

map = Map.new(lines)

visited = Set.new
total_cost = 0
map.each_point do |point|
  next if visited.include?(point)

  region = map.cell(point)
  area, corners = measure_region(region, map, point, visited)
  puts "Region #{region} at #{point} has area #{area} and #{corners} corners"
  total_cost += area * corners
end

puts "Total cost: #{total_cost}"
