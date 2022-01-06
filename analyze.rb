require_relative 'misc/stats'

files = ARGV
files = files.sort_by { |file|
  file
    .sub('jruby', 'sruby') # sort JRuby after CRuby
    .sub(/-([my]jit)/, '.\1') # sort MJIT/YJIT after interpreter
    .sub('jvm-ee', 'zvm-ee') # sort JVM EE after Native EE
}

results = files.to_h { |file|
  name = File.basename(file, '.*').sub(/^results-/, '')
  if File.basename(file).start_with?('results-')
    bench = "#{File.basename(File.dirname(file))} - "
  elsif File.dirname(File.dirname(file)).start_with?('results-')
    bench = "#{File.basename(File.dirname(file), '.*')} - "
  end

  desc, *samples = File.readlines(file, chomp: true)
  ["#{bench}#{desc} - #{name}", samples.map { |line| Float(line) }]
}

# base = results.keys.first
base = results.keys.find { |desc| desc.include?('ruby 3.1.0') }
base_median = Stats.new(results[base]).median

puts "\tspeedup\tmedian\taverage\t[min   -   max]"
results.map { |name, samples|
  # Take the second half of results, the first half is warmup
  times = samples[samples.size/2..-1]
  stats = Stats.new(times)
  median = stats.median
  avg = stats.mean
  min, max = stats.min, stats.max
  speedup = base_median / median
  f = '%.3f'
  puts "#{name}\n\t#{'%.2f' % speedup}x\t#{f % median}\t#{f % avg}\t[#{f % min} - #{f % max}]"
}
