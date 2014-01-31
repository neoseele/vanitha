#!/usr/bin/env ruby

require './base.rb'
require 'csv'
require 'pp'
require 'date'

class Worker < Base

  attr_accessor :options

  def sv_rows name
    rows = CSV.read(@options.sv, {headers: true, encoding: 'UTF-8'})
    rows.reject {|r| r['reason'].downcase != name.downcase}
  end

  def ec_rows path
    rows = CSV.read(path, {headers: true, encoding: 'UTF-8'})
    rows.reject {|r| r['transcript_speaker'].downcase == 'operator' }
  end

  def find_index ec_str, sv_str
    ec_str.sub(sv_str,'$').split('|').index('$')
  end

  def run
    Dir.glob(File.join(@options.ec_dir,'*.csv')) do |path|
      name = File.basename path, File.extname(path)

      out_path = File.join(@options.out_dir, File.basename(path))
      next if File.exist? out_path
      info "processing #{name}"

      ecs = ec_rows path
      svs = sv_rows name

      ec_str = ecs.collect{|r| r['transcript_speaker'].downcase}.join('|')
      sv_str = svs.collect{|r| "#{r['first_nm']} #{r['surname']}".downcase}.join('|')

      unless ec_str.include? sv_str
        err "can find a match for #{name}"
        next
      end

      i = find_index(ec_str, sv_str)
      @csv = [['ticker','date','time','reason','ca','first_nm','surname','affln','firm','jobt','no_words','no_questions','no_words_having_questions','start_time','end_time']]
      svs.each do |r|
        h = r.to_hash
        h['start_time'] = ecs[i]['start_time']
        h['end_time'] = ecs[i]['end_time']
        @csv << h.values
        i += 1
      end
      csv_out(File.join(@options.out_dir, File.basename(path)))
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
@opts.on('-s', '--sv File', String, 'Require: streetview csv') do |o|
  options.sv = o if File.exist?(o)
end
@opts.on('-e', '--ec_dir DIR', String, 'Require: earningcast dir') do |o|
  options.ec_dir = o if Dir.exist?(o)
end
@opts.on('-o', '--out_dir DIR', String, 'Require: output dir') do |o|
  options.out_dir = o if Dir.exist?(o)
end
@opts.on_tail("-h", "--help", "Show this message") do
  puts @opts
  exit
end
@opts.parse! rescue usage

### main
usage if options.sv.nil?
usage if options.ec_dir.nil?
usage if options.out_dir.nil?
w = Worker.new
w.options = options
w.run
