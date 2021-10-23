require 'benchmark'
require_relative 'stats'

MIN_ITERS = Integer(ENV['MIN_ITERS'] || 10)
MIN_TIME = Integer(ENV['MIN_TIME'] || 5)
MAX_TIME = Integer(ENV['MAX_TIME'] || 20 * 60)
MAD_TARGET = Float(ENV['MAD_TARGET'] || 0.001)
MAD_INCREASE_PER_ITER = Float(ENV['MAD_INCREASE_PER_ITER'] || 0.0001)

default_path = "results-#{RUBY_ENGINE}-#{RUBY_ENGINE_VERSION}-#{Time.now.strftime('%F-%H%M%S')}.csv"
OUT_CSV_PATH = File.expand_path(ENV.fetch('OUT_CSV_PATH', default_path))

puts RUBY_DESCRIPTION

def ms(seconds)
  (1000 * seconds).to_i
end

def monotonic_time
  Process.clock_gettime(Process::CLOCK_MONOTONIC)
end

# Takes a block as input
def run_benchmark(num_itrs_hint)
  start = monotonic_time
  times = []

  begin
    time = Benchmark.realtime { yield }
    times << time

    stats = Stats.new(times)
    median = stats.median
    mad = stats.median_absolute_deviation(median) / median
    extra_iters = times.size - MIN_ITERS
    threshold = extra_iters >= 0 ? MAD_TARGET + extra_iters * MAD_INCREASE_PER_ITER : 0.0

    puts "iter #%3d: %dms, mad=%.4f/%.4f, median=%dms" % [
      times.size,
      ms(time),
      mad,
      threshold,
      ms(median),
    ]

    elapsed = monotonic_time - start
    if elapsed >= MAX_TIME
      puts "timed out after #{(monotonic_time - start).to_i} seconds"
      break
    end
  end until times.size >= MIN_ITERS and elapsed >= MIN_TIME and mad <= threshold

  final_stats = Stats.new(times)
  puts "median: #{ms(final_stats.median)}ms"

  # Write each time value on its own line
  File.write(OUT_CSV_PATH, "#{RUBY_DESCRIPTION}\n#{times.join("\n")}\n")
end
