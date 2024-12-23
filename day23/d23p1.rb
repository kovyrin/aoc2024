#! /usr/bin/env ruby

# def walk_subnet(network, node, visited = Set.new)
#   visited.add(node)
#   puts "At #{node} with #{visited.inspect} already visited"

#   # find all nodes that are connected to the current node
#   network[node].keys.each do |neighbor|
#     next unless network[node][neighbor]
#     puts " - following connection to #{neighbor}"
#     walk_subnet(network, neighbor, visited) unless visited.include?(neighbor)
#   end

#   visited.to_a.sort
# end

network = Hash.new { |h, k| h[k] = Hash.new(false) }
input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file).map(&:strip).reject(&:empty?)

lines.each do |line|
  from, to = line.split('-')
  network[from][to] = true
  network[to][from] = true
end

puts "network.keys.size: #{network.keys.size}"

result = 0
computers = network.keys
computers.combination(3) do |a, b, c|
  next unless network[a][b] && network[b][c] && network[c][a]
  puts "Found #{a}, #{b}, #{c}"
  result += 1 if a.start_with?('t') || b.start_with?('t') || c.start_with?('t')
end

puts result
