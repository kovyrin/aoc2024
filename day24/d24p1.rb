#! /usr/bin/env ruby

def calculate(wires, wire)
  return wires[wire] unless wires[wire].is_a?(Hash)

  a, op, b = wires[wire].values_at(:a, :op, :b)
  a = calculate(wires, a)
  b = calculate(wires, b)

  wires[wire] = case op
    when "AND"
      a & b
    when "OR"
      a | b
    when "XOR"
      a ^ b
    end

  wires[wire]
end

input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file)

wires = {}
while line = lines.shift
  break if line.strip.empty?
  name, value = line.strip.split(":").map(&:strip)
  wires[name] = value.to_i == 1
end

while line = lines.shift
  eq, output = line.strip.split("->").map(&:strip)
  a, op, b = eq.split(" ")
  wires[output] = { a:, op: , b: }
end

z_wires = wires.keys.select { |k| k.start_with?("z") }
z_bits = ''

z_wires.sort.each do |wire|
  bit = calculate(wires, wire) ? 1 : 0
  z_bits << bit.to_s
end

z_bits = z_bits.reverse.to_i(2)
puts z_bits.inspect
