def stats(data)
  sorted = data.sort
  if data.size.odd?
    median = sorted[sorted.size / 2]
  else
    median = sorted[sorted.size / 2 - 1, 2].sum / 2
  end
  avg = sorted.sum / sorted.size.to_f
  min, max = sorted.minmax
  [median, avg, min, max]
end

files = ARGV

results = files.to_h { |file|
  name = File.basename(file, '.*').sub(/^results-/, '')
  desc, *samples = File.readlines(file, chomp: true)
  ["#{desc} - #{name}", samples.map { |line| Float(line) }]
}

base = results.keys.first
base_stats = stats(results[base])

puts "\tspeedup\tmedian\taverage\t[min   -   max]"
results.map { |name, samples|
  data = samples.last(10)
  median, avg, min, max = stats(data)
  speedup = base_stats[0] / median
  f = '%.3f'
  puts "#{name}\n\t#{'%.1f' % speedup}x\t#{f % median}\t#{f % avg}\t[#{f % min} - #{f % max}]"
}
