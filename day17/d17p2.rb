#! /usr/bin/env ruby

class ChronoSpatialComputer
  attr_reader :a, :b, :c, :program, :ip, :output

  def initialize(program)
    @program = program
    @ip = 0
    @output = []
  end

  def reset!(a:, b:, c:)
    @a = a
    @b = b
    @c = c
    @ip = 0
    @output = []
  end

  def run!
    while ip < program.size do
      instruction = program[ip]
      operand = program[ip + 1]

      # puts "ip: #{ip}, instruction: #{instruction}, operand: #{operand}"
      execute_instruction(instruction, operand)
      # puts "ip: #{ip}, a: #{a}, b: #{b}, c: #{c}, output: #{output.join(',')}"

      if output.size > 0
        last_output_idx = output.size - 1
        if output[last_output_idx] != program[last_output_idx]
          break
        end
      end
    end
  end

  def execute_instruction(instruction, operand)
    case instruction
      when 0 then execute_adv(operand)
      when 1 then execute_bxl(operand)
      when 2 then execute_bst(operand)
      when 3 then execute_jnz(operand)
      when 4 then execute_bxc(operand)
      when 5 then execute_out(operand)
      when 6 then execute_bdv(operand)
      when 7 then execute_cdv(operand)
      else raise "Unknown instruction #{instruction} with operand #{operand}"
    end
  end

  def combo_operand(operand)
    case operand
      when 0, 1, 2, 3 then operand
      when 4 then a
      when 5 then b
      when 6 then c
      when 7 then raise "Invalid combo operand: #{operand}"
    end
  end

  def execute_adv(operand)
    numerator = a
    denominator = 2**combo_operand(operand)
    @a = numerator / denominator # integer division, truncate the remainder
    @ip += 2
  end

  def execute_bxl(operand)
    @b = b ^ operand # Bitwise xor
    @ip += 2
  end

  def execute_bst(operand)
    @b = combo_operand(operand) % 8 # Combo operand modulo 8
    @ip += 2
  end

  def execute_jnz(operand)
    if a == 0
      @ip += 2
    else
      @ip = operand
    end
  end

  def execute_bxc(_operand)
    @b = b ^ c # Bitwise xor
    @ip += 2
  end

  def execute_out(operand)
    @output << (combo_operand(operand) % 8) # Combo operand modulo 8
    @ip += 2
  end

  def execute_bdv(operand)
    numerator = a
    denominator = 2**combo_operand(operand)
    @b = numerator / denominator # integer division, truncate the remainder
    @ip += 2
  end

  def execute_cdv(operand)
    numerator = a
    denominator = 2**combo_operand(operand)
    @c = numerator / denominator # integer division, truncate the remainder
    @ip += 2
  end
end

input_file = ENV['REAL'] ? "input.txt" : "input-demo2.txt"
lines = File.readlines(input_file)

_a, b, c, program = lines.map(&:strip).reject(&:empty?).map(&:split).map(&:last)

program = program.split(',').map(&:to_i)
b = b.to_i
c = c.to_i

computer = ChronoSpatialComputer.new(program)
longest_matching_output_size = 0
queue = [0]
min_correct_a = nil
explored_suffixes = Set.new

while queue.any?
  a_bit_suffix = queue.shift
  if explored_suffixes.include?(a_bit_suffix)
    puts "Already explored suffix #{a_bit_suffix.to_s(2)} (#{a_bit_suffix})"
    next
  end

  if min_correct_a && a_bit_suffix > min_correct_a
    puts "Skipping suffix #{a_bit_suffix.to_s(2)} (#{a_bit_suffix}) because it's greater than min_correct_a #{min_correct_a.to_s(2)} (#{min_correct_a})"
    next
  end

  2048.times do |a_prefix|
    a = (a_prefix << a_bit_suffix.bit_length) | a_bit_suffix
    if min_correct_a && a_prefix > min_correct_a
      puts "Skipping prefix #{a_prefix} because it's greater than min_correct_a #{min_correct_a.to_s(2)} (#{min_correct_a})"
      break
    end

    computer.reset!(a:, b:, c:)
    computer.run!

    if computer.output == program
      puts "Correct A: #{a}, min: #{min_correct_a}"
      min_correct_a = a if min_correct_a.nil? || a < min_correct_a
      break
    end

    matching_output = computer.output[0..-2]
    if matching_output.size >= longest_matching_output_size && matching_output.size > 0
      longest_matching_output_size = matching_output.size
      puts "New longest matching output at A=#{a} (#{a.to_s(2)}): #{matching_output.join(',')}"
      queue << a unless explored_suffixes.include?(a_bit_suffix)
    end
  end

  explored_suffixes << a_bit_suffix
end

puts "Ran out of queue"

puts "Correct A values: #{min_correct_a}"

# 202991746427439 - too high
# 202991746427434 - correct
