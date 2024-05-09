require_relative 'load_data'
require_relative 'misc/stats'

data = DATA[:data]
benchmarks = DATA[:benchmarks]

benchmarks.each do |bench|
  puts "\n#{bench}:"
  results = data.map { |ruby, benchs| [ruby, benchs[bench]] }.to_h

  base = results.keys.first
  # base = 'ruby'
  base_median = Stats.new(results.fetch(base).fetch("bench")).median
  longest_ruby = data.keys.max_by(&:size).size

  puts "#{' ' * longest_ruby} speedup\tmedian\taverage\t[min    -    max]"
  results.map { |ruby, result|
    if result
      # Take the second half of results, the first half is warmup
      # times = samples[samples.size/2..-1]
      times = result.fetch("bench")
      raise unless result.fetch("warmup").size >= times.size - 1
      stats = Stats.new(times)
      median = stats.median
      avg = stats.mean
      min, max = stats.min, stats.max
      speedup = base_median / median
      f = '%6.2f'
      puts "#{ruby.ljust(longest_ruby)} #{'%.2f' % speedup}x\t#{f % median}\t#{f % avg}\t[#{f % min} - #{f % max}]"
    else
      puts "#{ruby.ljust(longest_ruby)} ---------------- FAILED -----------------"
    end
  }
end
