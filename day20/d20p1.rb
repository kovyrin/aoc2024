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

  def self.step(direction)
    STEPS[direction]
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
  attr_reader :map, :best_finish_score, :finish

  def initialize(map, finish)
    @map = map
    @finish = finish

    @best_score_cache = Hash.new(Float::INFINITY)
    @best_finish_score = Float::INFINITY
  end

  def best_score_for(position)
    @best_score_cache[position.to_s]
  end

  def update_best_score(position, score)
    return if score.nil?
    @best_score_cache[position.to_s] = score if @best_score_cache[position.to_s] > score
  end

  def update_finish_score(score)
    @best_finish_score = score if score < best_finish_score
  end

  def max_path_depth
    @max_path_depth ||= map.width * map.height / 2
  end

  def walk_without_cheating(position:, seen: Set.new, score_so_far: 0)
    # Stop if we're already too deep
    return if score_so_far > max_path_depth

    # Do not walk on walls or off the map
    cell = map.cell(position)
    return if cell == '#' || cell.nil?

    # Do not revisit the same point
    return if seen.include?(position.to_s)

    # Early return if this path is already worse than our best for this situation or in general
    return if score_so_far >= best_score_for(position) || score_so_far >= best_finish_score

    # Record the best score for reaching this point with this direction.
    update_best_score(position, score_so_far)

    # Check if we are at the finish point.
    if position == finish
      puts "Finished at #{position} with score #{score_so_far} and path length #{seen.size}"
      update_finish_score(score_so_far)
      return score_so_far
    end

    # Do not revisit the same point with the same direction.
    seen = seen.dup
    seen << position.to_s

    # We have 4 options:
    next_score = score_so_far + 1
    results = [
      # 1. Move up
      walk_without_cheating(position: position + Direction.step(Direction::UP), seen:, score_so_far: next_score),

      # 2. Move down
      walk_without_cheating(position: position + Direction.step(Direction::DOWN), seen:, score_so_far: next_score),

      # 3. Move left
      walk_without_cheating(position: position + Direction.step(Direction::LEFT), seen:, score_so_far: next_score),

      # 4. Move right
      walk_without_cheating(position: position + Direction.step(Direction::RIGHT), seen:, score_so_far: next_score),
    ]

    results.compact.min
  end
end


#------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file).map(&:strip).reject(&:empty?)

map = Map.new(lines)
puts map.inspect

start = nil
finish = nil

map.each_point do |point|
  if map.cell(point) == 'S'
    start = point
  elsif map.cell(point) == 'E'
    finish = point
  end
end

path_finder = PathFinder.new(map, finish)
baseline_score = path_finder.walk_without_cheating(position: start)
puts "Baseline score: #{baseline_score}"
