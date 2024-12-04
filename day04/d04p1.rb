#! /usr/bin/env ruby

require 'active_support/all'

module Directions
  NORTH = { x: 0,  y: -1 }
  SOUTH = { x: 0,  y: +1 }
  WEST  = { x: -1, y: 0 }
  EAST  = { x: +1, y: 0 }

  NORTH_EAST = { x: +1, y: -1 }
  SOUTH_EAST = { x: +1, y: +1 }
  SOUTH_WEST = { x: -1, y: +1 }
  NORTH_WEST = { x: -1, y: -1 }

  # Directions where coordinates increase
  ALL = [NORTH, SOUTH, WEST, EAST, NORTH_EAST, SOUTH_EAST, SOUTH_WEST, NORTH_WEST]
end

class Map
  delegate :each_with_index, to: :@map

  def initialize(map)
    @map = map
  end

  def height
    @map.size
  end

  def width
    @map.first.size
  end

  def [](x, y)
    return nil if x < 0 || x >= width || y < 0 || y >= height
    @map[y][x]
  end
end

def spells_xmas?(map, start, direction)
  word = 'XMAS'
  x, y = start[:col], start[:row]

  word.each_char do |c|
    return false if map[x, y] != c
    x, y = x + direction[:x], y + direction[:y]
  end

  true
end

input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
map = Map.new(File.readlines(input_file).map(&:chars))

starts = []
map.each_with_index do |line, row|
  line.each_with_index do |c, col|
    starts << { col:, row: } if c == 'X'
  end
end

total_xmas = 0
starts.each do |start|
  Directions::ALL.each do |direction|
    if spells_xmas?(map, start, direction)
      puts "There is an XMAS spelled starting at #{start} and going #{direction}"
      total_xmas += 1
    end
  end
end

puts "Total XMAS: #{total_xmas}"
