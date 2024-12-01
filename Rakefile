task :env do
  path = ENV.fetch('PWD')
  Dir.chdir(path)
  day = path.split('/').last
  unless day =~ /day\d+/
    puts "ERROR: Needs to be in a day directory"
    exit(1)
  end

  @day = day.gsub('day', '').to_i
end

def run_part(part)
  script = "d%02dp%d.rb" % [@day, part]
  File.chmod(0755, script)
  system("ruby #{script}")
end

task :p1 => :env do
  run_part(1)
end

task :p2 => :env do
  run_part(2)
end
