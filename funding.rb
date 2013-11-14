#!/usr/bin/env ruby

require './base.rb'
require 'net/http'
require 'uri'
require 'nokogiri'

class String
  def is_i?
    !!(self =~ /^[-+]?[0-9]+$/)
  end
end

class Company
  attr_accessor :name, :type, :incorporated, :ticker, :year, :info

  def load(doc)
    main = doc.css('div#main-content')
    grid = main.css('div.quick-look > div.grid_10')

    @type = grid.css('strong')[0].text.strip

    i = grid.css('span[itemprop=foundingDate]')
    @incorporate = i.text.strip if i.any?

    t = grid.css('span[itemprop=tickerSymbol]')
    @ticker = t.text.strip if t.any?

    dl = main.css('dl')
    if dl.any?
      @year = dl.css('dt')[0].text.strip.gsub(/[^\d]+/,'') # remove anything that is not digit
      @info = dl.css('dd')[0].text.strip
    end
  end

end

class Fetcher < Base

  def get_http
    url = URI.parse('http://www.fundinguniverse.com')
    http = Net::HTTP.new url.host, url.port
    http.read_timeout = 500
    http
  end

  def get_doc(http, path)
    Nokogiri::HTML(http.get2(path).body)
  end

  def get_total(doc)
    total = 0
    doc.css('div.pagination > a[href]').each do |a|
      t = a.text.strip
      next unless t.is_i?
      n = t.to_i
      total = n unless total > n
    end
    total
  end

  def get_company_links(doc)
    doc.css('ul.company-list > li > a[href]').each_with_object({}) do |a, hash|
      hash[a.text.strip] = a['href']
    end
  end

  def create_company_obj(name, doc)
    c = Company.new
    c.name = name
    c.load doc
    c
  end

  def run
    # create a Net::HTTP obj
    http = get_http

    # total number of pages
    total = get_total(get_doc(http, '/company-histories/'))
    puts "Total Pages: [#{total}]"

    (1..total).each do |n|
      puts "Page: [#{n.to_s}] >>"
      doc = get_doc(http, "/company-histories/?page=#{n.to_s}")

      get_company_links(doc).each do |name,link|
        puts '* fetching ' + name
        c = create_company_obj(name, get_doc(http, URI(link).path))
        @csv << [c.name, c.type, c.incorporated, c.ticker, c.year, c.info, link]
      end
      break
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
@opts.on_tail("-h", "--help", "Show this message") do
   puts @opts
   exit
end
@opts.parse! rescue usage

### main
#usage if options.source.nil?
f = Fetcher.new
f.csv = [['name','type','incorporate','ticker','year','info','url']]
f.run
f.csv_out 'result.csv'
#pp f.csv

