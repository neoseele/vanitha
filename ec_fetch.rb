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

  def create_dir(name)
    path = [@dest,name].join(File::SEPARATOR)
    FileUtils.mkdir_p path
    path
  end

  def run
    doc = get_doc("#{SITE}/transcripts/list3")
    doc.css('table#transcript_details tbody').css('tr').each do |tr|
      tds = tr.css('td')

      is_processed = tds[8].text.strip.downcase == 'true'
      next unless is_processed

      # transcript name
      name = tds[1].text.strip
      info "fetching #{name}"

      # every transcript has its own dir for storing the downloaded files
      dir = create_dir(name)

      begin
        csv_link = tds[2].css('a').first['href']
        download(dir, "#{SITE}#{csv_link}")
      rescue
        err "#{name}: fail to download csv"
      end

      next unless @download_mp3

      begin
        mp3_link = tds[3].css('a').first['href']
        download(dir, mp3_link)
      rescue
        err "#{name}: fail to download mp3"
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
