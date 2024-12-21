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
        @movements_map[x][y] = walk_map(start:, finish:)
      end
    end
  end

  # Builds a path from the current button to the target button
  def walk_map(start:, finish:, path: [], seen: [])
    return path + ['A'] if start == finish

    return if seen.include?(start.to_s)
    seen << start.to_s

    # Cannot move over empty cells or out of bounds
    cell = map.cell(start)
    return if cell.nil? || cell == '.'

    # Move in all 4 directions
    results = [
      walk_map(start: start + Direction.step(UP), finish:, path: path + [UP], seen:),
      walk_map(start: start + Direction.step(DOWN), finish:, path: path + [DOWN], seen:),
      walk_map(start: start + Direction.step(LEFT), finish:, path: path + [LEFT], seen:),
      walk_map(start: start + Direction.step(RIGHT), finish:, path: path + [RIGHT], seen:),
    ].compact

    results.min_by { |result| result.size }
  end

  def type_sequence(sequence)
    pos = 'A'
    sequence = sequence.dup

    keys = []

    while button = sequence.shift
      keys += @movements_map[pos][button]
      pos = button
    end

    keys
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
  sequence = numeric_keypad.type_sequence(code)
  puts "#{code.join}: #{sequence.join} (length: #{sequence.size})"

  sequence2 = directional_keypad.type_sequence(sequence)
  puts "  Keypad 2: #{sequence2.join} (length: #{sequence2.size})"

  sequence3 = directional_keypad.type_sequence(sequence2)
  puts "  Keypad 3: #{sequence3.join} (length: #{sequence3.size})"
end
