#! /usr/bin/env ruby

#------------------------------------------------------------------------------
Point = Data.define(:x, :y) do
  def to_s
    "[#{x},#{y}]"
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

  def deep_dup
    Map.new(@lines.map(&:dup))
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
  attr_reader :map, :best_finish_score, :best_finish_score_cells, :finish

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

  def update_finish_score(score, path)
    @best_finish_score = score if score < best_finish_score
  end

  # Modified walk method that's now an instance method
  def walk(position:, seen: Set.new, path: Set.new, score_so_far: 0)
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
      # puts "Finished at #{position} with score #{score_so_far} and path length #{seen.size}"
      update_finish_score(score_so_far, path)
      return score_so_far
    end

    # Do not revisit the same point with the same direction.
    seen = seen.dup
    seen << position.to_s

    # We have 4 options:
    next_score = score_so_far + 1
    results = [
      # 1. Move up
      walk(position: position + Direction.new(Direction::UP).step, seen:, path:, score_so_far: next_score),

      # 2. Move down
      walk(position: position + Direction.new(Direction::DOWN).step, seen:, path:, score_so_far: next_score),

      # 3. Move left
      walk(position: position + Direction.new(Direction::LEFT).step, seen:, path:, score_so_far: next_score),

      # 4. Move right
      walk(position: position + Direction.new(Direction::RIGHT).step, seen:, path:, score_so_far: next_score),
    ]

    results.compact.min
  end
end

#------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file).map(&:strip).map { |line| x, y = line.split(',').map(&:to_i); Point.new(x, y) }

map_size = ENV['REAL'] ? 71 : 7
puts "Map size: #{map_size}"

puts "Total lines: #{lines.size}"
bytes_fallen = ENV['REAL'] ? 1024 : 12
fallen_lines = lines.take(bytes_fallen)
remaining_lines = lines.drop(bytes_fallen)
puts "Bytes fallen: #{bytes_fallen}"
puts "Remaining lines: #{remaining_lines.size}"

# Generate an empty map of the given size
map_lines = map_size.times.map { '.' * map_size }
clean_map = Map.new(map_lines)

# Mark the fallen lines on the map
fallen_lines.each { |p| clean_map.set(p, '#') }

start = Point.new(0, 0)
finish = Point.new(map_size - 1, map_size - 1)

# Now bisect the remaining lines until we find the earliest point that blocks the path
unpassable = (0..remaining_lines.size).bsearch do |take|
  map = clean_map.deep_dup
  puts "Applying #{take} lines out of #{remaining_lines.size}"
  apply_lines = remaining_lines.take(take)
  apply_lines.each { |p| map.set(p, '#') }

  # Find the path
  path_finder = PathFinder.new(map, finish)
  !path_finder.walk(position: start)
end

puts "Unpassable: #{remaining_lines[unpassable-1]}"

# 42,33 - incorrect
# 16,44 - correct
