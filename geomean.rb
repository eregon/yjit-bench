require_relative 'harness-warmup/stats'

macros = Dir["benchmarks/*/benchmark.rb"].sort
benchmarks = macros

results_dir = ARGV.fetch(0)

baseline = "ruby-3.1.0"

medians_per_engine = Hash.new { |h,k| h[k] = [] }

def compute_median(file)
  samples = File.readlines(file).drop(1).map { |line| Float(line) }
  # Take the second half of results, the first half is warmup
  times = samples[samples.size/2..-1]
  Stats.new(times).median
end

benchmarks.each do |benchmark|
  benchmark_name = if benchmark.end_with?('/benchmark.rb')
    File.basename(File.dirname(benchmark))
  else
    File.basename(benchmark, '.rb')
  end

  next if benchmark_name == 'jekyll'
  puts benchmark_name

  baseline_median = compute_median("#{results_dir}/#{benchmark_name}/results-#{baseline}.csv")

  files = Dir["#{results_dir}/#{benchmark_name}/results-*"]
  files.each do |file|
    engine = File.basename(file, '.*').sub(/^results-/, '')

    median = compute_median(file) / baseline_median

    medians_per_engine[engine] << median
  end
end

geomeans = medians_per_engine.transform_values { |medians|
  medians.reduce(:*) ** (1.0 / medians.size)
}

# pp medians_per_engine
p medians_per_engine.transform_values { |medians| medians.size }
pp geomeans

geomean_dir = "#{results_dir}/geomean"
Dir.mkdir(geomean_dir) unless Dir.exist?(geomean_dir)

geomeans.each_pair { |engine, geomean|
  File.write("#{geomean_dir}/results-#{engine}.csv", "geomean\n" + "#{geomean}\n" * 2)
}
