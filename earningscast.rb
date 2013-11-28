#!/usr/bin/env ruby

require './base.rb'
require 'uri'
require 'open-uri'
require 'nokogiri'

SITE='http://kata.earningscast.com'

class Fetcher < Base

  attr_accessor :dest, :download_mp3

  def get_doc(url)
    page = open(url, &:read)
    Nokogiri::HTML(page)
  end

  def run
    doc = get_doc("#{SITE}/list_transcripts2")

    doc.css('tr').each do |tr|
      all_td = tr.css('td')
      next unless all_td.length > 0 # skip the header row

      is_processed = all_td[7].text.strip.downcase == 'true'
      next unless is_processed

      name = all_td[0].text.strip
      info "fetching #{name}"

      tr.css('td > a').each do |a|
        txt = a.text.strip.downcase
        link = "#{SITE}#{a['href']}"
        download(@dest, link) if txt == 'download'
        download(@dest, link) if @download_mp3 && link =~ /.*download_mp3.*/
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
@opts.on('-d', "--dest DIR", String, 'Require: download destination') do |o|
    options.dest = o if Dir.exist?(o)
end
@opts.on('-m', "--[no-]mp3", 'Download mp3') do |o|
    options.download_mp3 = o
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
f.download_mp3 = options.download_mp3
f.run
