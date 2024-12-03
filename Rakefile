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

task :generate_day do
  day = ENV['DAY'] or raise "Needs a DAY"
  day = day.to_i

  puts "Generating dir for day #{day}..."
  template_dir = Dir.pwd + '/day_template'
  day_dir = Dir.pwd + ('/day%02d' % day)
  FileUtils.mkdir_p(day_dir)

  Dir.glob(template_dir + '/*').each do |f|
    FileUtils.cp(f, day_dir + '/')
  end

  template_file = day_dir + '/dXXpX.rb'
  FileUtils.cp(template_file, day_dir + ('/d%02dp1.rb' % day))
  FileUtils.cp(template_file, day_dir + ('/d%02dp2.rb' % day))
  File.unlink(template_file)
end
