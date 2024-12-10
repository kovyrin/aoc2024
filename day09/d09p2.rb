#! /usr/bin/env ruby

AocFile = Struct.new(:block_id, :length, :position, :is_moved)
EmptySpace = Struct.new(:length, :position, :is_moved)

input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
disk_map = File.readlines(input_file).first.chomp

# Render the compressed disk map into a list of file blocks
file_blocks = []
file_id = 0
position = 0
empty_block = false

disk_map.each_char do |char|
  length = char.to_i
  file_blocks << (empty_block ? EmptySpace.new(length, position, false) : AocFile.new(file_id, length, position, false))
  file_id += 1 unless empty_block

  empty_block = !empty_block
  position += length
end

# Defragment the disk map by moving the file blocks to the empty space
resulting_blocks = []

#
# TODO: Implement the second part of the puzzle
#

# Calculate the checksum of the resulting disk map
checksum = 0
resulting_blocks.each do |block|
  0.upto(block.length - 1) do |i|
    pos = block.position + i
    checksum += pos * block.block_id
  end
end

puts checksum
