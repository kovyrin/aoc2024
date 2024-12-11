#! /usr/bin/env ruby

AocFile = Struct.new(:block_id, :length, :position)
EmptySpace = Struct.new(:length, :position)

input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
disk_map = File.readlines(input_file).first.chomp

# Render the compressed disk map into a list of file blocks
file_blocks = []
file_id = 0
position = 0
empty_block = false

disk_map.each_char do |char|
  length = char.to_i
  file_blocks << (empty_block ? EmptySpace.new(length, position) : AocFile.new(file_id, length, position))
  file_id += 1 unless empty_block

  empty_block = !empty_block
  position += length
end

# Separate the empty blocks from the filled blocks to make it easier to iterate over them
empty_blocks = file_blocks.select { |block| block.is_a?(EmptySpace) }
filled_blocks = file_blocks.select { |block| block.is_a?(AocFile) }

# Walk filled blocks from the last one and try to move each of them into the first empty block where they'd fit
filled_blocks.reverse_each do |block|
  # Look for the first empty block that fits it
  empty_blocks.each do |empty_block|
    next if empty_block.length < block.length
    next if empty_block.position > block.position

    puts "Moving block #{block.block_id} from #{block.position} to #{empty_block.position}"
    block.position = empty_block.position

    empty_block.length -= block.length
    empty_block.position += block.length
    break
  end
end

# It does not matter in which order we calculate the checksum,
# but let's order the blocks by their position for easier debugging
resulting_blocks = filled_blocks.sort_by { |block| block.position }

# Calculate the checksum of the resulting disk map
checksum = 0
resulting_blocks.each do |block|
  0.upto(block.length - 1) do |i|
    pos = block.position + i
    checksum += pos * block.block_id
  end
end

puts checksum

# 8560706397829 - too high
# 6418529470362 - correct
