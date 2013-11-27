#!/usr/bin/env ruby

require './base.rb'
require 'uri'
require 'open-uri'
require 'nokogiri'

SITE='http://kata.earningscast.com'

class Fetcher < Base

  attr_accessor :dest

  def get_doc(url)
    page = open(url, &:read)
    Nokogiri::HTML(page)
  end

  def run
    doc = get_doc("#{SITE}/list_transcripts2")

    doc.css('td > a[href]').each do |a|
      link = "#{SITE}#{a['href']}"
      download @dest, link
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
@opts.on('-d', "--dest DIR", String, 'Require: download destination') do |d|
    options.dest = d if Dir.exist?(d)
end
@opts.on_tail("-h", "--help", "Show this message") do
   puts @opts
   exit
end
@opts.parse! rescue usage

### main
usage if options.dest.nil?
f = Fetcher.new
f.dest = options.dest
f.run
