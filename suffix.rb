#!/usr/bin/env ruby

require './base.rb'

class Parser < Base

  def parse(source)
    data = CSV.read(source, :headers => false, :encoding => 'UTF-8').collect do |r|
      lname = r[1]
      lname_nosuffix = r[4]
      suffix = r[5]
      unless lname =~ /,/
        segments = lname.split
        if segments.length >= 2
          if ['jr','sr','ii','iii','iv'].include? segments[-1].downcase
            r[4] = segments[0..-2].join ' '
            r[5] = segments[-1]
          end
        end
      end
      r
    end
    @csv = data
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
@opts.on('-s', "--source FILE", String, 'Require: input source') do |s|
  options.source = s if File.exist?(s)
end
@opts.on_tail("-h", "--help", "Show this message") do
  puts @opts
  exit
end
@opts.parse! rescue usage

### main
usage if options.source.nil?

p = Parser.new
p.parse options.source
p.csv_out 'result.csv'
