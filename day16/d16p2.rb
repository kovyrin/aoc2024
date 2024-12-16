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
end

#------------------------------------------------------------------------------
class Direction
  UP = :up
  DOWN = :down
  LEFT = :left
  RIGHT = :right

  STEPS = {
    UP => Point.new(0, -1),
    DOWN => Point.new(0, 1),
    LEFT => Point.new(-1, 0),
    RIGHT => Point.new(1, 0),
  }.freeze

  TURN_RIGHT = {
    UP => RIGHT,
    RIGHT => DOWN,
    DOWN => LEFT,
    LEFT => UP,
  }.freeze

  TURN_LEFT = {
    UP => LEFT,
    LEFT => DOWN,
    DOWN => RIGHT,
    RIGHT => UP,
  }.freeze

  attr_reader :direction

  def initialize(direction)
    @direction = direction
  end

  # Pre-create instances for each direction
  INSTANCES = {
    UP => new(UP),
    DOWN => new(DOWN),
    LEFT => new(LEFT),
    RIGHT => new(RIGHT),
  }.freeze

  def self.new(direction)
    INSTANCES[direction] || super
  end

  def to_s
    @direction.to_s
  end

  def turn_right
    INSTANCES[TURN_RIGHT[@direction]]
  end

  def turn_left
    INSTANCES[TURN_LEFT[@direction]]
  end

  def step
    STEPS[@direction]
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
class PathFinder
  attr_reader :map, :best_finish_score, :best_finish_score_cells

  def initialize(map)
    @map = map
    @best_score_cache = Hash.new(Float::INFINITY)
    @best_finish_score = Float::INFINITY
    @recording_cells = false
    @best_finish_score_cells = Set.new
  end

  def enable_recording_cells!
    @recording_cells = true
  end

  def cache_key(position, direction)
    position.to_s + '|' + direction.to_s
  end

  def best_score_for(position_hash)
    @best_score_cache[position_hash]
  end

  def update_best_score(position_hash, score)
    return if score.nil?
    @best_score_cache[position_hash] = score if @best_score_cache[position_hash] > score
  end

  def update_finish_score(score, path)
    if score < best_finish_score
      @best_finish_score = score
      @best_finish_score_cells = path.dup if @recording_cells
    elsif score == best_finish_score
      @best_finish_score_cells.merge(path) if @recording_cells
    end
  end

  def max_path_depth
    @max_path_depth ||= map.width * map.height / (ENV['REAL'] ? 10 : 2)
  end

  # Modified walk method that's now an instance method
  def walk(position:, direction:, seen: Set.new, path: Set.new, score_so_far: 0)
    # Do not walk on walls.
    return if map.cell(position) == '#'

    # Do not revisit the same point with the same direction.
    position_hash = cache_key(position, direction)
    return if seen.include?(position_hash)

    # Early return if this path is already worse than our best for this situation or in general
    if @recording_cells
      return if score_so_far > best_score_for(position_hash) || score_so_far > best_finish_score
    else
      return if score_so_far >= best_score_for(position_hash) || score_so_far >= best_finish_score
    end

    # Stop if we're already too deep
    return if seen.size > max_path_depth

    # Record the best score for reaching this point with this direction.
    update_best_score(position_hash, score_so_far)

    # Add the current position to the path
    if @recording_cells
      path = path.dup
      path << position
    end

    # Check if we are at the finish point.
    tile = map.cell(position)
    if tile == 'E'
      puts "Finished at #{position} with score #{score_so_far} and path length #{seen.size}"
      update_finish_score(score_so_far, path)
      return score_so_far
    end

    # Do not revisit the same point with the same direction.
    seen = seen.dup
    seen << position_hash

    # We have three options:
    results = [
      # 1. Move forward - score +1
      walk(position: position + direction.step, direction:, seen:, path:, score_so_far: score_so_far + 1),

      # 2. Turn left - score +1000
      walk(position:, direction: direction.turn_left, seen:, path:, score_so_far: score_so_far + 1000),

      # 3. Turn right - score +1000
      walk(position:, direction: direction.turn_right, seen:, path:, score_so_far: score_so_far + 1000),
    ]

    results.compact.min
  end
end

#------------------------------------------------------------------------------

input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file).map(&:strip).reject(&:empty?)

map = Map.new(lines)
puts map

start = nil
finish = nil

map.each_point do |point|
  if map.cell(point) == 'S'
    start = point
  elsif map.cell(point) == 'E'
    finish = point
  end
end

puts "Start: #{start}"
puts "Finish: #{finish}"

# We always start facing east
direction = Direction.new(Direction::RIGHT)

path_finder = PathFinder.new(map)
lowest_score = path_finder.walk(position: start, direction:)
puts "Lowest score: #{lowest_score}"

puts "Re-walking with recording enabled applying the same best score cache, etc"
path_finder.enable_recording_cells!
lowest_score = path_finder.walk(position: start, direction:)
puts "Lowest score: #{lowest_score}"
puts "Best finish score cells: #{path_finder.best_finish_score_cells.count}"
