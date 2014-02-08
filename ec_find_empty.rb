#!/usr/bin/env ruby

require './base.rb'
require 'csv'

class Worker < Base

  attr_accessor :options

  def read_csv path
    CSV.read(path, {headers: true, encoding: 'UTF-8'})
  end

  def run
    Dir.glob(File.join(@options.input_dir,'*.csv')) do |path|
      name = File.basename path, File.extname(path)
      @stdout.info "processing #{name}"
      err "#{name} is empty" if read_csv(path).empty?
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
@opts.on('-i', '--input DIR', String, 'Require: input dir') do |o|
  options.input_dir = o if Dir.exist?(o)
end
@opts.on_tail("-h", "--help", "Show this message") do
  puts @opts
  exit
end
@opts.parse! rescue usage

### main
usage if options.input_dir.nil?
w = Worker.new
w.options = options
w.run
