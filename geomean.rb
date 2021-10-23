require_relative 'load_data'
require_relative 'misc/stats'

data = DATA[:data]
benchmarks = []

baseline = "ruby-3.3.5" # "ruby"

medians_per_engine = Hash.new { |h,k| h[k] = [] }

def compute_median(samples)
  # Take the second half of results, the first half is warmup
  times = samples[samples.size/2..-1]
  Stats.new(times).median
end

data.each_pair { |ruby, benchs_data|
  benchs_data.each_pair { |bench, samples|
    # next if %w[liquid-c ruby-lsp sequel].include?(bench)
    benchmarks << bench unless benchmarks.include? bench

    baseline_median = compute_median(data.fetch(baseline).fetch(bench))
    median = baseline_median / compute_median(samples)
    medians_per_engine[ruby] << median
  }
}

geomeans = medians_per_engine.transform_values { |medians|
  medians.reduce(:*) ** (1.0 / medians.size)
}

# pp medians_per_engine
sizes = medians_per_engine.transform_values { |medians| medians.size }
raise sizes.inspect unless sizes.uniq.size != 1

puts "Geomean for these benchmarks:"
puts benchmarks.join(" ")

# pp geomeans
longest_ruby = data.keys.max_by(&:size).size
data.keys.each do |ruby|
  puts "#{ruby.ljust(longest_ruby)} #{'%.2f' % geomeans[ruby]}"
end

# geomean_dir = "#{results_dir}/geomean"
# Dir.mkdir(geomean_dir) unless Dir.exist?(geomean_dir)
#
# geomeans.each_pair { |engine, geomean|
#   File.write("#{geomean_dir}/results-#{engine}.csv", "geomean\n" + "#{geomean}\n" * 2)
# }
