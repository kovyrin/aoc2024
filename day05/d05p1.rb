#! /usr/bin/env ruby

def correct_order?(pages, rules)
  puts "Checking #{pages}:"
  applying_rules = rules.select do |rule|
    pages.include?(rule[0]) && pages.include?(rule[1])
  end
  puts " - Applying rules: #{applying_rules.inspect}"

  seen_pages = Set.new
  pages.each do |page|
    pages_after_current = applying_rules.select { |rule| rule[0] == page }.map(&:last)

    if seen_pages.intersection(pages_after_current).any?
      puts " - Current page: #{page}"
      puts " - The following pages need to be printed after #{page}: #{pages_after_current.join(", ")}"
      puts " - But we have already seen: #{seen_pages.intersection(pages_after_current).join(", ")}"
      return false
    end


    pages_before_current = applying_rules.select { |rule| rule[1] == page }.map(&:first)
    if seen_pages.intersection(pages_before_current).size != pages_before_current.size
      puts " - Current page: #{page}"
      puts " - The following pages need to be printed before #{page}: #{pages_before_current.join(", ")}"
      puts " - But the following pages are missing: #{pages_before_current.reject { |page| seen_pages.include?(page) }.join(", ")}"
      return false
    end

    seen_pages.add(page)
  end

  true
end

input_file = ENV['REAL'] ? "input.txt" : "input-demo.txt"
lines = File.readlines(input_file)

rules = []
loop do
  line = lines.shift
  break if line.nil? || line.strip.empty?

  rules << line.split("|").map(&:to_i)
end

pp rules

correct_lists = []
lines.each do |line|
  pages = line.split(",").map(&:to_i)
  correct_lists << pages if correct_order?(pages, rules)
  puts
end

puts "----------------------------------------"
puts "Total correct lists: #{correct_lists.size}"
pp correct_lists

puts "----------------------------------------"
result = 0
correct_lists.each do |pages|
  mid_element = pages[pages.size / 2]
  result += mid_element
end
puts "Result: #{result}"
