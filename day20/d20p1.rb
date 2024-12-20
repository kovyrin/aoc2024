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
  attr_reader :map, :best_finish_score, :finish, :best_path

  def initialize(map, finish)
    @map = map
    @finish = finish
    @best_finish_score = Float::INFINITY
    @best_path = nil
    @best_score_for = Hash.new(Float::INFINITY) # best score for a given position
  end

  def update_score_for(position, score)
    @best_score_for[position.to_s] = score if score < @best_score_for[position.to_s]
  end

  def score_for(position)
    @best_score_for[position.to_s]
  end

  def update_finish_score(score, path)
    if score < best_finish_score
      @best_finish_score = score
      @best_path = path
    end
  end

  def max_path_depth
    @max_path_depth ||= map.width * map.height / 2
  end

  def walk_without_cheating(position:, seen: Set.new, steps: 0, path: [])
    # Stop if we're already too deep
    return if steps > max_path_depth || steps >= best_finish_score || steps >= score_for(position)

    # Do not walk on walls or off the map
    cell = map.cell(position)
    return if cell == '#' || cell.nil?

    # Do not revisit the same point
    return if seen.include?(position.to_s)
    seen = (seen.dup << position.to_s)
    path = (path.dup << position)

    update_score_for(position, steps)

    # Check if we are at the finish point.
    if position == finish
      update_finish_score(steps, path)
      return steps
    end

    steps += 1
    results = [
      walk_without_cheating(position: position + Direction.step(Direction::UP), seen:, steps:, path:),
      walk_without_cheating(position: position + Direction.step(Direction::DOWN), seen:, steps:, path:),
      walk_without_cheating(position: position + Direction.step(Direction::LEFT), seen:, steps:, path:),
      walk_without_cheating(position: position + Direction.step(Direction::RIGHT), seen:, steps:, path:),
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

# Walk backwards from the finish point to the start point
# This means that the best score we record for each point will be the distance from that point to the finish
path_finder = PathFinder.new(map, start)
baseline_score = path_finder.walk_without_cheating(position: finish)
puts "Baseline score: #{baseline_score}"

track_path = path_finder.best_path.reverse

cheat_length = 2
cheat_successes = Hash.new(0)

track_path.each do |point|
  score = path_finder.score_for(point)
  puts "Point: #{point}, distance to finish: #{score}"

  # Check all possible jumps from the current point where we land back on the track
  0.upto(cheat_length * 2) do |x|
    0.upto(cheat_length * 2) do |y|
      x_change = x - cheat_length
      y_change = y - cheat_length

      jump_length = x_change.abs + y_change.abs
      next if jump_length < 1 || jump_length > cheat_length

      puts " - Attempting jump: #{x_change}, #{y_change}"
      jump = Point.new(x_change, y_change)
      landing = point + jump
      landing_cell = map.cell(landing)
      next if landing_cell == '#' || landing_cell.nil? # cannot land on walls or off the map

      puts "   - Looks like a good landing: #{landing}"

      # Check how much better it would make our score (how much it would save us in steps)
      cheat_score = path_finder.score_for(landing)
      savings = score - cheat_score - jump_length

      # Only count cheats as successes if they bring us closer to the finish
      if savings > 0
        puts "   - Savings: #{savings}"
        cheat_successes[savings] += 1
      end
    end
  end
end

puts "----------------------------------------"
puts "Cheat successes:"
cheat_successes.sort_by { |savings, count| -savings }.each do |savings, count|
  puts " - #{savings}: #{count}"
end

if ENV['REAL']
  threshold = 100
  puts "Total jumps saving #{threshold} or more steps: #{cheat_successes.select { |savings, count| savings >= threshold }.values.sum}"
end
