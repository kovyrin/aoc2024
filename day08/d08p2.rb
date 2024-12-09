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

  def *(scalar)
    Point.new(x * scalar, y * scalar)
  end

  def distance(other)
    (x - other.x).abs + (y - other.y).abs
  end

  def vector(other)
    Point.new(other.x - x, other.y - y)
  end

  def prime_vector
    gcd = x.gcd(y)
    Point.new(x / gcd, y / gcd)
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
    prime_vector = vector.prime_vector

    max_vector_repeats = [map.width / prime_vector.x, map.height / prime_vector.y].max
    0.upto(max_vector_repeats) do |i|
      candidates = [
        antenna1 + prime_vector * i,
        antenna2 + prime_vector * i,
        antenna1 - prime_vector * i,
        antenna2 - prime_vector * i
      ]

      candidates.each do |candidate|
        anti_points.add(candidate) if map.cell(candidate)
      end
    end
  end
end

puts "Anti-point count: #{anti_points.size}"

# 381 - correct
