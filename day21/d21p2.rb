#! /usr/bin/env ruby

#------------------------------------------------------------------------------
Point = Struct.new(:x, :y) do
  def +(other)
    Point.new(x + other.x, y + other.y)
  end
end

#------------------------------------------------------------------------------
class Map
  attr_reader :width, :height

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
UP = '^'
DOWN = 'v'
LEFT = '<'
RIGHT = '>'

module Direction
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
NUMERIC_KEYPAD = [
  "789",
  "456",
  "123",
  ".0A"
].freeze

DIRECTIONAL_KEYPAD = [
  ".^A",
  "<v>",
].freeze

class Keypad
  attr_reader :buttons, :map, :movements_map

  def initialize(buttons_map)
    @map = Map.new(buttons_map)

    @buttons = {}
    @map.each_point do |point|
      button = @map.cell(point)
      @buttons[button] = point if button != '.'
    end

    @movements_map = {}
  end

  # Builds a map of movement sequences needed to move a robot arm from button X to the button Y
  def build_movements_map
    @buttons.each do |x, start|
      @movements_map[x] = {}
      @buttons.each do |y, finish|
        paths = Set.new
        walk_map(start:, finish:, paths:)
        @movements_map[x][y] = paths
      end
    end
  end

  # Builds a path from the current button to the target button
  def walk_map(start:, finish:, path: [], paths:)
    # Cannot move over empty cells or out of bounds
    cell = map.cell(start)
    return if cell.nil? || cell == '.'

    if start == finish
      sorted_path = path.sort
      if sorted_path == path || sorted_path == path.reverse # do not flip directions more than once during the path
        paths << path + ['A']
        return path
      end
    end

    results = []
    results << walk_map(start: start + Direction.step(UP), finish:, path: path + [UP], paths:) if start.y > finish.y
    results << walk_map(start: start + Direction.step(DOWN), finish:, path: path + [DOWN], paths:) if start.y < finish.y
    results << walk_map(start: start + Direction.step(LEFT), finish:, path: path + [LEFT], paths:) if start.x > finish.x
    results << walk_map(start: start + Direction.step(RIGHT), finish:, path: path + [RIGHT], paths:) if start.x < finish.x
    results.compact.min_by { |result| result.size }
  end

  # Builds all possible ways we can type
  def type_code(code:, current_button: 'A', path: [], results: Set.new)
    if code.empty?
      results << path
      return results
    end

    # All possible ways we can type the next button
    code = code.dup
    next_button = code.shift
    movements = @movements_map[current_button][next_button]
    movements.each do |movement|
      type_code(code:, current_button: next_button, path: path + movement, results:)
    end

    results
  end

  def type_code_recursive(code:, depth:)
    sequences = type_code(code:)
    return sequences.min_by { |sequence| sequence.size } if depth == 1

    sequences.map do |sequence|
      type_code_recursive(code: sequence, depth: depth - 1)
    end.min_by { |sequence| sequence.size }
  end
end

numeric_keypad = Keypad.new(NUMERIC_KEYPAD)
numeric_keypad.build_movements_map

directional_keypad = Keypad.new(DIRECTIONAL_KEYPAD)
directional_keypad.build_movements_map

#------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
codes = File.readlines(input_file).map(&:strip).reject(&:empty?).map(&:chars)

num_dir_keypads = 2

total_complexity = 0
codes.each do |code|
  min_human_sequence = nil

  sequences = numeric_keypad.type_code(code:)
  sequences.each do |sequence|
    shortest_numeric_sequence = directional_keypad.type_code_recursive(code: sequence, depth: num_dir_keypads)

    if min_human_sequence.nil? || shortest_numeric_sequence.size < min_human_sequence.size
      min_human_sequence = shortest_numeric_sequence
    end
  end

  puts "Minimum human sequence for #{code.join}: #{min_human_sequence.join.size}"
  complexity = min_human_sequence.size * code.filter { |c| c.match?(/[0-9]/) }.join.to_i
  puts "Complexity: #{complexity}"
  total_complexity += complexity
end

puts "Total complexity: #{total_complexity}"
