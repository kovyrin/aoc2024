#! /usr/bin/env ruby

def bron_kerbosch(r, p, x, network, maximal_clique = Set.new)
  if p.empty? && x.empty?
    # Only consider if larger than previous maximal clique
    if maximal_clique.nil? || r.size > maximal_clique.size
      maximal_clique.clear
      maximal_clique.merge(r)
    end
    return maximal_clique
  end

  pivot = p.first # Pick a random pivot
  non_neighbors = p - network[pivot]

  non_neighbors.each do |v|
    r.add(v)
    next_p = p & network[v]
    next_x = x & network[v]
    bron_kerbosch(r, next_p, next_x, network, maximal_clique)
    r.delete(v)
    x.add(v)
  end

  maximal_clique
end

network = Hash.new { |h, k| h[k] = Set.new }
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file).map(&:strip).reject(&:empty?)

lines.each do |line|
  from, to = line.split('-')
  network[from].add(to)
  network[to].add(from)
end

puts "network.keys.size: #{network.keys.size}"

r = Set.new
p = Set.new(network.keys)
x = Set.new

result = bron_kerbosch(r, p, x, network)
result = result.to_a.sort
puts "result: #{result.join(',')} (size: #{result.size})"

# am,au,be,cm,fo,ha,hh,im,nt,os,qz,rr,so - good
