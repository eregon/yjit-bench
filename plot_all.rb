macros = Dir["benchmarks/*/benchmark.rb"].sort
micros = Dir["benchmarks/*.rb"].sort
# benchmarks = macros + micros + ['benchmarks/geomean.rb']
benchmarks = macros + ['benchmarks/geomean.rb']

results_dir = ARGV.fetch(0)

benchmarks.each do |benchmark|
  benchmark_name = if benchmark.end_with?('/benchmark.rb')
    File.basename(File.dirname(benchmark))
  else
    File.basename(benchmark, '.rb')
  end

  next if benchmark_name == 'jekyll'
  puts benchmark_name

  files = Dir["#{results_dir}/#{benchmark_name}/results-*"]
  Dir.mkdir 'graphs' unless Dir.exist? 'graphs'
  out_file = "graphs/#{benchmark_name}"
  system 'python3', 'plot_benchmark.py', '--out_file', out_file, *files, exception: true
end
