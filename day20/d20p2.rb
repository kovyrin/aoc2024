#! /usr/bin/env ruby

#------------------------------------------------------------------------------
Point = Struct.new(:x, :y) do
  def +(other)
    Point.new(x + other.x, y + other.y)
  end
end

#------------------------------------------------------------------------------
module Direction
  UP = :up
  DOWN = :down
  LEFT = :left
  RIGHT = :right
  ALL = [UP, DOWN, LEFT, RIGHT].freeze

  STEPS = {
    UP => Point.new(0, -1),
    DOWN => Point.new(0, 1),
    LEFT => Point.new(-1, 0),
    RIGHT => Point.new(1, 0),
  }.freeze

  def self.step(direction)
    STEPS[direction]
  end
end

#------------------------------------------------------------------------------
class Map
  def initialize(lines)
    @lines = lines
    @width = lines.first.size
    @height = lines.size
  end

  def cell(point)
    return nil if point.y < 0 || point.y >= @height
    return nil if point.x < 0 || point.x >= @width

    @lines[point.y][point.x]
  end

  def each_point
    0.upto(@height - 1) do |y|
      0.upto(@width - 1) do |x|
        yield Point.new(x, y)
      end
    end
  end
end

#------------------------------------------------------------------------------
class PathFinder
  attr_reader :map, :finish, :path, :score_for

  def initialize(map, finish)
    @map = map
    @finish = finish
    @score_for = Hash.new(Float::INFINITY) # best score for a given position
    @path = []
  end

  def update_score_for_position(position, score)
    hash = position.y * 1000 + position.x
    @score_for[hash] = score if score < @score_for[hash]
  end

  def score_for_position(position)
    hash = position.y * 1000 + position.x
    @score_for[hash]
  end

  def walk(position:)
    queue = [position]

    while (current_pos = queue.shift)
      # Skip invalid positions
      cell = map.cell(current_pos)
      next if cell == '#' || cell.nil?

      steps = @path.size
      next if steps >= score_for_position(current_pos)

      # Update best score and path
      path << current_pos
      update_score_for_position(current_pos, steps)

      # Check if we reached the finish
      return path if current_pos == finish

      # Add neighbors to queue
      Direction::ALL.each do |dir|
        queue << (current_pos + Direction.step(dir))
      end
    end

    nil
  end
end

#------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file).map(&:strip).reject(&:empty?)

map = Map.new(lines)

start = nil
finish = nil

map.each_point do |point|
  case map.cell(point)
    when 'S' then start = point
    when 'E' then finish = point
  end
end

# Walk backwards from the finish point to the start point
# This means that the best score we record for each point will be the distance from that point to the finish
path_finder = PathFinder.new(map, start)
path = path_finder.walk(position: finish)

cheat_length = 20
cheat_successes = 0
success_threshold = ENV['REAL'] ? 100 : 50

path.each do |point|
  score = path_finder.score_for_position(point)

  # Replace each_within_manhattan_distance with direct nested loops
  cheat_range = (-cheat_length..cheat_length)
  cheat_range.each do |x_change|
    cheat_range.each do |y_change|
      manhattan_distance = x_change.abs + y_change.abs
      next if manhattan_distance > cheat_length || manhattan_distance == 0

      x = point.x + x_change
      y = point.y + y_change

      # Check how much better it would make our score (how much it would save us in steps)
      hash = y * 1000 + x
      cheat_score = path_finder.score_for[hash]
      next if cheat_score == Float::INFINITY

      # Only count cheats as successes if they bring us closer to the finish
      savings = score - cheat_score - manhattan_distance
      cheat_successes += 1 if savings >= success_threshold
    end
  end
end

puts "Total successes: #{cheat_successes}"

# 993178 - correct
