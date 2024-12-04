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

  ALL = [NORTH, SOUTH, WEST, EAST, NORTH_EAST, SOUTH_EAST, SOUTH_WEST, NORTH_WEST]
  STRAIGHT = [NORTH, SOUTH, WEST, EAST]
  DIAGONAL = [NORTH_EAST, SOUTH_EAST, SOUTH_WEST, NORTH_WEST]
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

def spells_mas?(map, start, direction)
  word = 'MAS'
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
    starts << { col:, row: } if c == 'M'
  end
end

mas_instances = []
starts.each do |start|
  Directions::DIAGONAL.each do |direction|
    if spells_mas?(map, start, direction)
      puts "There is an MAS spelled starting at #{start} and going #{direction}"
      mas_instances << { start:, direction: }
    end
  end
end

mas_centers = Hash.new(0)
mas_instances.each do |instance|
  x, y = instance[:start][:col], instance[:start][:row]
  ax, ay = x + instance[:direction][:x], y + instance[:direction][:y]
  mas_centers[[ax, ay]] += 1
end

crosses = mas_centers.select { |_, count| count > 1 }

puts "Total MAS: #{mas_instances.size}"
puts "Crosses: #{crosses.size}"
