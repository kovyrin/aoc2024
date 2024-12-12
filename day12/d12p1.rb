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
def measure_region(region, map, point, visited)
  return 0, 0 if visited.include?(point)
  point_plant = map.cell(point)
  return 0, 0 if point_plant != region
  visited.add(point)

  area = 1
  perimeter = 0

  Direction::ALL.each do |dir|
    neighbor = point + dir
    neighbor_plant = map.cell(neighbor)

    if neighbor_plant != region
      perimeter += 1
    else
      neighbor_area, neighbor_perimeter = measure_region(region, map, neighbor, visited)
      area += neighbor_area
      perimeter += neighbor_perimeter
    end
  end

  [area, perimeter]
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
  area, perimeter = measure_region(region, map, point, visited)
  total_cost += perimeter * area
end

puts "Total cost: #{total_cost}"
