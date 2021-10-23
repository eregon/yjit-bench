benchmarks = ENV['BENCHMARKS'] ? ENV['BENCHMARKS'].split : ARGV
if benchmarks.empty?
  # benchmarks = Dir["benchmarks/*.rb"].sort + Dir["benchmarks/*/benchmark.rb"].sort
  benchmarks = Dir["benchmarks/*/benchmark.rb"].sort # only macros
end

exclude = (ENV['EXCLUDE'] || 'jekyll').split(',')

dry_run = ENV['DRY_RUN'] == "true"
if dry_run
  # Same as ./run_once.sh
  ENV['WARMUP_ITRS'] = '0'
  ENV['MIN_BENCH_ITRS'] = '1'
  ENV['MIN_BENCH_TIME'] = '0'
  harness = './harness'
else
  harness = './harness-warmup'
end

RETRY = dry_run ? 1 : 2

puts
puts "Benchmarking #{RUBY_DESCRIPTION}"
puts "harness: #{harness}, dry-run: #{dry_run}"

# Undo lockfile modifications from running ruby-master
raise unless system 'git', 'checkout', 'benchmarks/*/Gemfile.lock'

now = Time.now
results_dir = "results-#{now.strftime('%F')}"
Dir.mkdir results_dir unless File.directory?(results_dir)

benchmarks.each do |benchmark|
  script = benchmark

  benchmark_name = if benchmark.end_with?('/benchmark.rb')
    File.basename(File.dirname(benchmark))
  else
    File.basename(benchmark, '.rb')
  end

  puts
  if exclude.include?(benchmark_name)
    puts "Skipping #{benchmark_name}"
  else
    puts benchmark_name

    sub_dir = "#{results_dir}/#{benchmark_name}"
    Dir.mkdir sub_dir unless File.directory?(sub_dir)

    if RUBY_ENGINE == 'truffleruby'
      /GraalVM (CE|EE) (Native|JVM)/ =~ RUBY_DESCRIPTION
      ruby_name = "truffleruby-#{$2.downcase}-#{$1.downcase}"
    else
      ruby_name = "#{RUBY_ENGINE}-#{RUBY_ENGINE_VERSION}"
      ruby_name += '-yjit' if defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
      ruby_name += '-mjit' if defined?(RubyVM::MJIT) && RubyVM::MJIT.enabled?
    end

    ENV['OUT_CSV_PATH'] = "#{sub_dir}/results-#{ruby_name}.csv"

    retries = RETRY
    begin
      retries -= 1
      result = system 'ruby', "-I#{harness}", File.realpath(script)
      puts "#{script} failed!" unless result
    end while !result and retries > 0
    unless result
      abort "#{script} failed #{RETRY} times, aborting!"
    end
  end
end
