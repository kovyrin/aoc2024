#! /usr/bin/env ruby

class CliqueFinder
  attr_reader :maximal_clique, :network

  def initialize(network)
    @network = network
    @maximal_clique = Set.new
  end

  def bron_kerbosch(current: Set.new, candidates:, excluded: Set.new)
    if candidates.empty? && excluded.empty?
      @maximal_clique = current.to_a.sort if current.size > maximal_clique.size
      return @maximal_clique
    end

    pivot = candidates.first # Pick a pivot node (makes it a lot faster)
    non_neighbors = candidates - network[pivot]

    non_neighbors.each do |v|
      current.add(v)
      next_p = candidates & network[v]
      next_x = excluded & network[v]
      bron_kerbosch(current: current, candidates: next_p, excluded: next_x)
      current.delete(v)
      excluded.add(v)
    end

    maximal_clique
  end
end

network = Hash.new { |h, k| h[k] = Set.new }
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file).map(&:strip).reject(&:empty?)

lines.each do |line|
  from, to = line.split('-')
  network[from].add(to)
  network[to].add(from)
end

clique_finder = CliqueFinder.new(network)
result = clique_finder.bron_kerbosch(candidates: Set.new(network.keys))
puts "result: #{result.join(',')}"

# am,au,be,cm,fo,ha,hh,im,nt,os,qz,rr,so - good
