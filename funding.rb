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

def get_company_list(doc)
  doc.css('ul.company-list > li > a[href]').each_with_object({}) do |a, hash|
    hash[a.text.strip] = a['href']
  end
end

def get_company_details(doc)
end

total = get_total(PAGE)

test = []
(1..1).each do |n|
  doc = get_doc("#{PAGE}?page=#{n.to_s}")
  test << get_company_list(url)
end

pp test.length
pp test
