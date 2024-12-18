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
    @recording_cells = false
    @best_finish_score_cells = Set.new
  end

  def enable_recording_cells!
    @recording_cells = true
  end

  def best_score_for(position)
    @best_score_cache[position.to_s]
  end

  def update_best_score(position, score)
    return if score.nil?
    @best_score_cache[position.to_s] = score if @best_score_cache[position.to_s] > score
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
    @max_path_depth ||= map.width * map.height
  end

  # Modified walk method that's now an instance method
  def walk(position:, seen: Set.new, path: Set.new, score_so_far: 0)
    # Do not walk on walls or off the map
    cell = map.cell(position)
    return if cell == '#' || cell.nil?

    # Do not revisit the same point
    return if seen.include?(position.to_s)

    # Early return if this path is already worse than our best for this situation or in general
    if @recording_cells
      return if score_so_far > best_score_for(position) || score_so_far > best_finish_score
    else
      return if score_so_far >= best_score_for(position) || score_so_far >= best_finish_score
    end

    # Stop if we're already too deep
    return if seen.size > max_path_depth

    # Record the best score for reaching this point with this direction.
    update_best_score(position, score_so_far)

    # Add the current position to the path
    if @recording_cells
      path = path.dup
      path << position
    end

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

# Parse the coordinates of corrupted cells and mark them on the map
fallen_lines.each do |p|
  clean_map.set(p, '#')
end

start = Point.new(0, 0)
finish = Point.new(map_size - 1, map_size - 1)

# Now bisect the remaining lines until we find the earliest point that blocks the path
# We will use this point in the list of lines to figure out how many lines to take
# Then keep moving the breaking point until we find the last point that still allows the path
bisect_step = remaining_lines.size / 2
breaking_point = remaining_lines.size
last_passable = 0

loop do
  map = clean_map.deep_dup
  puts "---------------------------------------"

  puts "Applying #{breaking_point} lines out of #{remaining_lines.size}"
  apply_lines = remaining_lines.take(breaking_point)
  # puts "Applying #{apply_lines.inspect} lines"
  apply_lines.each do |p|
    map.set(p, '#')
  end

  # Draw the map
  # puts map.inspect

  # Find the path
  path_finder = PathFinder.new(map, finish)
  shortest_path = path_finder.walk(position: start)

  # If we could still walk the map, we need more lines
  if shortest_path
    puts "Found path of length #{shortest_path} after applying #{apply_lines.size} lines, adding #{bisect_step} more lines"
    last_passable = breaking_point if breaking_point > last_passable
    breaking_point += bisect_step
  else
    if bisect_step == 1
      puts "The path is blocked by #{apply_lines.size} lines, we're done"
      puts "Last passable point number: #{last_passable}"
      puts "Last passable point: #{remaining_lines[last_passable-1]}"
      puts "First blocking point: #{remaining_lines[last_passable]}"
      break
    end

    puts "The path is blocked by #{apply_lines.size} lines, removing #{bisect_step} lines"
    breaking_point -= bisect_step
  end

  bisect_step /= 2 unless bisect_step == 1
end

# 42,33 - incorrect
