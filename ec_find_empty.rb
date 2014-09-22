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
      data = read_csv(path)
      if data.empty?
        err "#{name} is empty"
        next
      end
      time_empty = false
      data.each do |r|
        time_empty ||= r[13].nil? # start_time
        time_empty ||= r[14].nil? # end_time
        break if time_empty
      end
      err "#{name}: start/end time is empty"
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
