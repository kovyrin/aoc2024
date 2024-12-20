#! /usr/bin/env ruby

#------------------------------------------------------------------------------
Point = Data.define(:x, :y) do
  def to_s
    "[#{x},#{y}]"
  end

  def +(other)
    Point.new(x + other.x, y + other.y)
  end


  def manhattan_distance(other)
    (x - other.x).abs + (y - other.y).abs
  end

  def each_within_manhattan_distance(distance)
    (-distance..distance).each do |x_change|
      (-distance..distance).each do |y_change|
        manhattan_distance = x_change.abs + y_change.abs
        next if manhattan_distance > distance || manhattan_distance == 0

        yield self + Point.new(x_change, y_change), manhattan_distance
      end
    end
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
  attr_reader :map, :finish, :final_path

  def initialize(map, finish)
    @map = map
    @finish = finish
    @final_path = nil
    @best_score_for = Hash.new(Float::INFINITY) # best score for a given position
  end

  def update_score_for(position, score)
    @best_score_for[position.to_s] = score if score < @best_score_for[position.to_s]
  end

  def score_for(position)
    @best_score_for[position.to_s]
  end

  def walk_without_cheating(position:, path: [])
    steps = path.size
    return if steps >= score_for(position)

    # Do not walk on walls or off the map
    cell = map.cell(position)
    return if cell == '#' || cell.nil?

    path << position
    update_score_for(position, steps)

    # Check if we are at the finish point.
    if position == finish
      @final_path = path
      return steps
    end

    walk_without_cheating(position: position + Direction.step(Direction::UP), path:) ||
      walk_without_cheating(position: position + Direction.step(Direction::DOWN), path:) ||
      walk_without_cheating(position: position + Direction.step(Direction::LEFT), path:) ||
      walk_without_cheating(position: position + Direction.step(Direction::RIGHT), path:)
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
baseline_score = path_finder.walk_without_cheating(position: finish)
puts "Baseline score: #{baseline_score}"

cheat_length = 20
cheat_successes = Hash.new(0)
success_threshold = ENV['REAL'] ? 100 : 50

path_finder.final_path.each do |point|
  score = path_finder.score_for(point)

  # Check all possible jumps from the current point where we land back on the track
  point.each_within_manhattan_distance(cheat_length) do |landing, jump_distance|
    # Check how much better it would make our score (how much it would save us in steps)
    cheat_score = path_finder.score_for(landing)
    savings = score - cheat_score - jump_distance

    # Only count cheats as successes if they bring us closer to the finish
    cheat_successes[savings] += 1 if savings >= success_threshold
  end
end

puts "Total successes: #{cheat_successes.values.sum}"

# 993178 - correct
