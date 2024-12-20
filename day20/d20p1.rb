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
    @best_finish_score = Float::INFINITY
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

    # Early return if this path is already worse than our best for this situation or in general
    return if score_so_far >= best_finish_score

    # Do not revisit the same point
    return if seen.include?(position.to_s)
    seen = (seen.dup << position.to_s)

    # Check if we are at the finish point.
    if position == finish
      update_finish_score(score_so_far)
      return score_so_far
    end

    next_score = score_so_far + 1
    results = [
      walk_without_cheating(position: position + Direction.step(Direction::UP), seen:, score_so_far: next_score),
      walk_without_cheating(position: position + Direction.step(Direction::DOWN), seen:, score_so_far: next_score),
      walk_without_cheating(position: position + Direction.step(Direction::LEFT), seen:, score_so_far: next_score),
      walk_without_cheating(position: position + Direction.step(Direction::RIGHT), seen:, score_so_far: next_score),
    ]

    results.compact.min
  end
end

#------------------------------------------------------------------------------
class PathFinderWithCheating < PathFinder
  attr_reader :cheat_step, :target_score, :cheated

  def initialize(map, finish, cheat_step, target_score)
    super(map, finish)
    @cheat_step = cheat_step
    @target_score = target_score
    @cheated = false
  end

  # The same walk as above, but allowed to walk on walls during steps cheat_step and cheat_step + 1
  def walk_with_cheating(position:, seen: Set.new, steps: 0)
    # Stop if we're already too deep
    return if steps > max_path_depth || steps > target_score

    # Do not walk on walls or off the map
    cell = map.cell(position)
    return if cell.nil?
    if cell == '#'
      if steps == cheat_step || steps == cheat_step + 1
        @cheated = true # we cheated during this step and walked on a wall
      else
        return nil # can't walk on walls
      end
    end

    # We were supposed to cheat, but we didn't (since there were no walls to walk on)
    return if steps > cheat_step + 1 && !cheated

    # Early return if this path is already worse than our best for this situation or in general
    return if steps >= best_finish_score

    # Do not revisit the same point
    return if seen.include?(position.to_s)
    seen = (seen.dup << position.to_s)

    # Check if we are at the finish point.
    if position == finish
      update_finish_score(steps)
      return steps
    end

    steps += 1
    results = [
      walk_with_cheating(position: position + Direction.step(Direction::UP), seen:, steps:),
      walk_with_cheating(position: position + Direction.step(Direction::DOWN), seen:, steps:),
      walk_with_cheating(position: position + Direction.step(Direction::LEFT), seen:, steps:),
      walk_with_cheating(position: position + Direction.step(Direction::RIGHT), seen:, steps:),
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

# We want to aim for saving at least 100 steps by cheating
target_score = ENV['REAL'] ? baseline_score - 100 : baseline_score

savings_counts = Hash.new(0)
0.upto(target_score-1) do |cheat_step|
  puts "Cheating starting at #{cheat_step} steps..."
  path_finder = PathFinderWithCheating.new(map, finish, cheat_step, target_score)
  score = path_finder.walk_with_cheating(position: start)
  unless score
    puts "- Failed to cheat during step #{cheat_step}"
    next
  end

  savings = baseline_score - score

  if savings > 0
    savings_counts[savings] += 1
    puts "Successfully cheated during step #{cheat_step} and saved #{savings} steps"
  else
    puts "Failed to cheat during step #{cheat_step}"
  end
end

savings_counts.sort_by { |savings, count| savings }.each do |savings, count|
  puts "Saved #{savings} steps: #{count} times"
end
