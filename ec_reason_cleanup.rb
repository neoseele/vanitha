#!/usr/bin/env ruby

require './base.rb'
require 'csv'
require 'pp'

class Worker < Base

  attr_accessor :options

  def read_csv path
    CSV.read(path, {headers: true, encoding: 'UTF-8'})
  end

  def run
    src = @options.source
    out = src.sub(File.extname(src),'_1.csv')

    data = read_csv src
    CSV.open(out, 'w') do |o|
      o << data.headers
      data.each do |r|
        r['reason'] = r['reason'].gsub('/',' ')
        o << r
      end
    end
  end
end

def usage
  puts @opts
  exit 1
end

### options
options = OpenStruct.new
@opts = OptionParser.new
@opts.banner = "Usage: #{File.basename($0)} [options]"
@opts.on('-s', '--source File', String, 'Require: source') do |o|
  options.source = o if File.exist?(o)
end
@opts.on_tail("-h", "--help", "Show this message") do
  puts @opts
  exit
end
@opts.parse! rescue usage

### main
usage if options.source.nil?

w = Worker.new
w.options = options
w.run
