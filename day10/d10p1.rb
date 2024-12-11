#! /usr/bin/env ruby

class Map
  def initialize(lines)
    @lines = lines.map(&:chars).map { |line| line.map(&:to_i) }
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
    @lines.map(&:join).join("\n")
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

module Direction
  UP = Point.new(0, -1)
  DOWN = Point.new(0, +1)
  LEFT = Point.new(-1, 0)
  RIGHT = Point.new(+1, 0)

  ALL = [UP, DOWN, LEFT, RIGHT]
end

#------------------------------------------------------------------------------
# Returns a set of peaks reachable from the given starting point
def peaks_reachable_from(map, start)
  elevation = map.cell(start)
  return Set.new unless elevation
  return Set.new([start]) if elevation == 9

  result = Set.new
  Direction::ALL.each do |dir|
    if map.cell(start + dir) == elevation + 1
      result += peaks_reachable_from(map, start + dir)
    end
  end

  result
end

#------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file).map(&:strip).reject(&:empty?)

map = Map.new(lines)
puts map.inspect

# Find all trailheads (points with a value of 0)
trailheads = []
map.each_point do |point|
  trailheads << point if map.cell(point) == 0
end
puts "Found #{trailheads.size} trailheads"
puts trailheads.inspect

# For each trailhead, find the number of 9s that could be reached from it
total_score = 0
trailheads.each do |trailhead|
  puts "Trailhead at #{trailhead}"
  peaks = peaks_reachable_from(map, trailhead)
  score = peaks.size
  puts "- Score: #{score}"
  total_score += score
end

puts "Total score: #{total_score}"

# 744 - correct
