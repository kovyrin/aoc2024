#! /usr/bin/env ruby

class ChronoSpatialComputer
  attr_reader :a, :b, :c, :program, :ip, :output

  def initialize(a:, b:, c:, program:)
    @a = a.to_i
    @b = b.to_i
    @c = c.to_i
    @program = program.split(',').map(&:to_i)
    @ip = 0
    @output = []
  end

  def run!
    while ip < program.size do
      instruction = program[ip]
      operand = program[ip + 1]

      puts "ip: #{ip}, instruction: #{instruction}, operand: #{operand}"
      execute_instruction(instruction, operand)
      puts "ip: #{ip}, a: #{a}, b: #{b}, c: #{c}, output: #{output.join(',')}"
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

input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file)

a, b, c, program = lines.map(&:strip).reject(&:empty?).map(&:split).map(&:last)

computer = ChronoSpatialComputer.new(a:, b:, c:, program:)
computer.run!
puts computer.output.join(',')


# 7,4,2,0,5,0,5,3,7 - correct
