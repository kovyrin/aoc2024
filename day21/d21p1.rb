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
        good_paths = []
        walk_map(start:, finish:, good_paths:)
        smallest = good_paths.min_by { |path| path.size }
        @movements_map[x][y] = good_paths.select { |path| path.size == smallest.size }
      end
    end
  end

  # Builds a path from the current button to the target button
  def walk_map(start:, finish:, path: [], seen: [], good_paths:)
    if start == finish
      path << 'A'
      good_paths << path
      return path
    end

    return if seen.include?(start.to_s)
    seen << start.to_s

    # Cannot move over empty cells or out of bounds
    cell = map.cell(start)
    return if cell.nil? || cell == '.'

    # Move in all 4 directions
    results = [
      walk_map(start: start + Direction.step(UP), finish:, path: path + [UP], seen:, good_paths:),
      walk_map(start: start + Direction.step(DOWN), finish:, path: path + [DOWN], seen:, good_paths:),
      walk_map(start: start + Direction.step(LEFT), finish:, path: path + [LEFT], seen:, good_paths:),
      walk_map(start: start + Direction.step(RIGHT), finish:, path: path + [RIGHT], seen:, good_paths:),
    ].compact

    results.min_by { |result| result.size }
  end

  # Builds all possible ways we can type
  def type_code(code, robot_pos = 'A', path = [], results = Set.new)
    if code.empty?
      results << path
      return
    end

    # All possible ways we can type the next button
    code = code.dup
    button = code.shift
    movements = @movements_map[robot_pos][button]

    movements.each do |movement|
      type_code(code, button, path + movement, results)
    end

    results
  end
end

numeric_keypad = Keypad.new(NUMERIC_KEYPAD)
numeric_keypad.build_movements_map

directional_keypad = Keypad.new(DIRECTIONAL_KEYPAD)
directional_keypad.build_movements_map

#------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
codes = File.readlines(input_file).map(&:strip).reject(&:empty?).map(&:chars)

codes.each do |code|
  puts "Robot typing code: #{code.join}"

  min_human_sequence = nil

  sequences = numeric_keypad.type_code(code)
  sequences.each do |sequence|
    sequences2 = directional_keypad.type_code(sequence)
    sequences2.each do |sequence2|
      sequences3 = directional_keypad.type_code(sequence2)
      sequences3.each do |sequence3|
        if min_human_sequence.nil? || sequence3.size < min_human_sequence.size
          min_human_sequence = sequence3
        end
      end
    end
  end

  puts "Minimum human sequence: #{min_human_sequence.join} (length: #{min_human_sequence.size})"
end
