require 'json'

json = JSON.load(File.read(ARGV.fetch(0)))
ruby_descriptions = json.fetch("metadata")
data = json.fetch("raw_data")
benchmarks = data.first.last.keys

order = data.keys
order = order.sort_by { |name|
  name
    .sub('jruby', 'sruby') # sort JRuby after CRuby
    .sub(/([my]jit)/, 'ruby-\1') # sort MJIT/YJIT after interpreter
    .sub('jvm-ee', 'zvm-ee') # sort JVM EE after Native EE
}

ordered_data = {}
order.each { |name| ordered_data[name] = data[name] }
data = ordered_data

DATA = {
  ruby_descriptions: ruby_descriptions,
  benchmarks: benchmarks,
  data: data,
}
