#!/usr/bin/env ruby

require './base.rb'
require 'csv'
require 'pp'
require 'date'

class Worker < Base

  attr_accessor :source, :dest

  def run
    Dir.glob(File.join(@source,'*.csv')) do |path|
      @csv = [['name','transcript_speaker','date','start_time','end_time','transcript_text']]
      transcript = File.basename(path)
      name = File.basename(path, '.csv')
      info "processing: #{name}"
      begin
        rows = CSV.read(path, {headers: true, encoding: 'UTF-8'})
      rescue
        err "cannot read: #{transcript}"
        next
      end

      rows.each do |row|
        begin
          start_dt = DateTime.strptime(row['Start Time'], '%d/%m/%Y %H:%M:%S:%L')
          date = start_dt.strftime('%F')
          start_time = start_dt.strftime('%T:%L')
        rescue
          date = ''
          start_time = ''
        end

        begin
          end_dt = DateTime.strptime(row['End Time'], '%d/%m/%Y %H:%M:%S:%L')
          end_time = end_dt.strftime('%T:%L')
        rescue
          end_time = ''
        end
        @csv << [name, row['Transcript Speaker'], date, start_time, end_time, row['Transcript Text']]
        csv_out(File.join(@dest, transcript))
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
@opts.on('-d', "--dest DIR", String, 'Require: destination directory') do |o|
    options.dest = o if Dir.exist?(o)
end
@opts.on_tail("-h", "--help", "Show this message") do
   puts @opts
   exit
end
@opts.parse! rescue usage

### main
usage if options.source.nil?
w = Worker.new
w.source = options.source
w.dest = options.dest
w.run
