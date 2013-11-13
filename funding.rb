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

  # parse from div.quick-look > div.grid_10
  def type(doc)
    pp doc
    @type = doc.css('strong')[0].text.strip
  end

  def incorporated(doc)
    tmp = doc.css('span[itemprop=foundingDate]')
    @incorporate = tmp.text.strip if tmp.any?
  end

  def ticker(doc)
    tmp = doc.css('span[itemprop=tickerSymbol]')
    @ticker = tmp.text.strip if tmp.any?
  end

  # parse from div#main-content
  def info(doc)
    # "key dates" are wrapped in the only "dl" in the page
    dl = doc.css('dl')
    if dl.any?
      pp dl.css('dt')
      pp dl.css('dd')
    end
  end
end

class Fetcher < Base

  def get_doc(url)
    Nokogiri::HTML(Net::HTTP.get(URI.parse(url)))
  end

  def get_total(doc)
    total = 0
    doc.css('.pagination > a[href]').each do |a|
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

    grid10 = doc.css('div.quick-look > div.grid_10')
    c.type grid10
    puts 1
    c.incorporated grid10
    c.ticker grid10

    main = doc.css('div#main-content')
    c.info main
    c
  end

  def run
    total = get_total(get_doc(PAGE))

    (1..1).each do |n|
      doc = get_doc("#{PAGE}?page=#{n.to_s}")
      get_company_links(doc).each do |name,link|
        puts '* fetching ' + name
        c = create_company_obj(name, get_doc(link))
        pp c
#        @csv << [c.name, c.type, c.incorporated, c.ticker, c.year, c.info]
        break
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
@opts.on_tail("-h", "--help", "Show this message") do
   puts @opts
   exit
end
@opts.parse! rescue usage

### constants
PAGE = 'http://www.fundinguniverse.com/company-histories/'

### main
#usage if options.source.nil?
f = Fetcher.new
f.csv = [["name","type","incorporate","year","info"]]
f.run
#f.csv_out 'result.csv'
pp f.csv

