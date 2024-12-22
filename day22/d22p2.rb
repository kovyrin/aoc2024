#! /usr/bin/env ruby

class RandomGenerator
  def initialize(seed)
    @seed = seed
  end

  def next
    mix_and_prune(@seed * 64)
    mix_and_prune(@seed / 32)
    mix_and_prune(@seed * 2048)

    @seed
  end

  def mix_and_prune(a)
    @seed = (@seed ^ a) % 16_777_216
  end
end

#---------------------------------------------------------------------------------
input_file = ENV['REAL'] ? "input.txt" : "input-demo2.txt"
seeds = File.readlines(input_file).map(&:strip).reject(&:empty?).map(&:to_i)

shared_ngrams = Hash.new(0)

seeds.each do |seed|
  random_generator = RandomGenerator.new(seed)
  previous_price = seed % 10
  price_diff_pairs = []

  2000.times do
    number = random_generator.next
    price = number % 10
    diff = price - previous_price
    previous_price = price
    price_diff_pairs << {price: price, diff: diff}
  end

  # generate all price n-grams of length 4 and record each n-gram with the price at the end of the n-gram
  ngram_length = 4
  seen_ngrams = Set.new
  price_diff_pairs.each_cons(ngram_length) do |window|
    price = window.last[:price]
    ngram = window.map { |p| p[:diff] }

    next if seen_ngrams.include?(ngram)
    seen_ngrams.add(ngram)

    shared_ngrams[ngram] += price
  end
end

ngram, price = shared_ngrams.max_by { |ngram, price| price }
puts "Best ngram: #{ngram.join(',')} -> #{price}"
