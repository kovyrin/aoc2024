#! /usr/bin/env ruby

class RandomGenerator
  def initialize(seed)
    @seed = seed
  end

  def next
    a = @seed * 64
    mix(a)
    prune!

    b = @seed / 32
    mix(b)
    prune!

    c = @seed * 2048
    mix(c)
    prune!

    @seed
  end

  def mix(a)
    @seed = @seed ^ a
  end

  def prune!
    @seed = @seed % 16_777_216
  end
end

#---------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
seeds = File.readlines(input_file).map(&:strip).reject(&:empty?).map(&:to_i)

sum_of_secrets = 0
seeds.each do |seed|
  puts "Seed: #{seed}"
  random_generator = RandomGenerator.new(seed)
  1999.times { random_generator.next }
  secret_number = random_generator.next
  puts "#{seed}: 2000th random number: #{secret_number}"
  sum_of_secrets += secret_number
end

puts "Sum of secrets: #{sum_of_secrets}"
