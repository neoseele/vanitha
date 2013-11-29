#!/usr/bin/env ruby

require './base.rb'
require 'csv'
require 'pp'

class Extractor < Base

  attr_accessor :source

  def run
    Dir.glob(File.join(@source,'*.csv')) do |path|
      transcript = File.basename(path)
      info "processing: #{transcript}"
      begin
        first_row = CSV.read(path, {headers: true, encoding: 'UTF-8'})[0]
        @csv << [transcript, first_row['Start Time']]
      rescue
        err "extraction failed: #{transcript}"
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
@opts.on('-s', "--source DIR", String, 'Require: source directory') do |o|
    options.source = o if Dir.exist?(o)
end
@opts.on_tail("-h", "--help", "Show this message") do
   puts @opts
   exit
end
@opts.parse! rescue usage

### main
usage if options.source.nil?
f = Extractor.new
f.source = options.source
f.csv = [['transcript','start_time']]
f.run
f.csv_out 'result.csv'
