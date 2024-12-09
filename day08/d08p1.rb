#! /usr/bin/env ruby
# frozen_string_literal: true

require 'set'

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
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file).map(&:strip).reject(&:empty?)

map = Map.new(lines)

# Collect antennas by type
antennas_by_type = Hash.new { |h, k| h[k] = [] }
map.each_point do |point|
  antenna_type = map.cell(point)
  antennas_by_type[antenna_type] << point if antenna_type != '.'
end

anti_points = Set.new

antennas_by_type.each do |antenna_type, antennas|
  antennas.combination(2).each do |antenna1, antenna2|
    vector = antenna1.vector(antenna2)

    anti_point1 = antenna2 + vector
    anti_point2 = antenna1 - vector

    anti_points.add(anti_point1) if map.cell(anti_point1)
    anti_points.add(anti_point2) if map.cell(anti_point2)
  end
end

puts "Anti-point count: #{anti_points.size}"

# 381 - correct
