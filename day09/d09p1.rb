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
file_blocks.each do |block|
  # We have reached the first moved block, which means the rest will have been moved as well
  break if block.is_moved

  # Move data blocks as-is
  if block.is_a?(AocFile)
    resulting_blocks << block
    block.is_moved = true
    next
  end

  # Collect enough blocks from the end of the list to fill the empty space
  file_blocks.reverse_each do |tail_block|
    next if tail_block.is_moved
    next if tail_block.is_a?(EmptySpace)
    next if tail_block.length == 0

    # The tail block fits completely in the empty space
    if tail_block.length < block.length
      resulting_blocks << AocFile.new(tail_block.block_id, tail_block.length, block.position, true)
      tail_block.is_moved = true
      block.length -= tail_block.length
      block.position += tail_block.length
      next
    end

    # The tail block fits partially in the empty space
    # Create a new file block to fill the empty space
    resulting_blocks << AocFile.new(tail_block.block_id, block.length, block.position, true)

    # Shorten the tail block by the same amount
    tail_block.length -= block.length
    tail_block.is_moved = true if tail_block.length == 0

    # The empty space is now filled, so we can stop
    block.length = 0
    block.is_moved = true
    break
  end
end

# Calculate the checksum of the resulting disk map
checksum = 0
resulting_blocks.each do |block|
  0.upto(block.length - 1) do |i|
    pos = block.position + i
    checksum += pos * block.block_id
  end
end

puts checksum

# 6395800119709 - correct
