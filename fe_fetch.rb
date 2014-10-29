#!/usr/bin/env ruby

require './base.rb'
require 'uri'
require 'open-uri'
require 'nokogiri'
require 'pp'
#require 'openssl'

URL = 'http://www.sciencedirect.com/science/journal/0304405X'
FRAG_URL_PREFIX = 'http://www.sciencedirect.com/science/frag/'
ALTER_URL = 'https://www.sciencedirect.com.ezproxy.library.uq.edu.au/science/journal/0304405X'
#FRAG_URL_PREFIX = 'https://www.sciencedirect.com.ezproxy.library.uq.edu.au/science/frag/'

class String
  def is_i?
    self.to_i.to_s == self
  end
end

class Article
  attr_accessor :volume, :issue, :title, :url, :pages, :authors, :parent_url

  def print
    puts @title
    puts @url
    puts @pages
    puts @authors
    puts @affiliation
    puts @footnote
  end

  def fetch
    doc = Nokogiri::HTML(open(@url).read)

    script_code = ''
    doc.css('script').each { |s| script_code += s.text }

    frag_fat = script_code.split("\n").select { |l| l =~ /^SDM\.pf\.frag\.fat/ }[0]
    frag_code = /\'(.*)\'/.match(frag_fat)[1]

    # url: http://www.sciencedirect.com/science/article/pii/0304405X74900063
    id = url.split('/')[-1]

    f1_url = "#{FRAG_URL_PREFIX}/#{id}/#{frag_code}/frag_1"
    @affiliation = Nokogiri::HTML(open(f1_url).read).css('ul.affiliation > li').map {|li| li.text.strip }.join('|')

    f2_url = "#{FRAG_URL_PREFIX}/#{id}/#{frag_code}/frag_2"
    @footnote = Nokogiri::HTML(open(f2_url).read).css('dl.footnote > dd > p').text.strip
  end

  def to_ary
    [@volume, @issue, @title, @pages, @authors, @affiliation, @footnote]
  end

end

class Fetcher < Base

  def run(from, to)
    (from..to).each do |volume|
      out = "vol#{volume}.csv"
      # skip if this volume is already fetched
      if File.exist? out
        info "Vol:#{volume} fetched already (#{out})"
        next
      end

      @csv = [['volume','issue','title','pages','authors','affiliation','footnote']]

      (1..10).each do |issue|
        info "volume: #{volume} - issue #{issue}"
        begin
          url = "#{URL}/#{volume}/#{issue}"
          #puts "[ #{url} ]"
          info "non-restricted link: #{ALTER_URL}/#{volume}/#{issue}"
          doc = Nokogiri::HTML(open(url).read)

          doc.css('ol.articleList > li.detail > ul.article').each do |article|
            a = article.css('li.title > h4 > a').first
            title = a.text

            paper = Article.new
            paper.volume = volume
            paper.issue = issue
            paper.title = title
            paper.url = a['href']
            paper.pages = article.css('li.source > i').text
            paper.authors = article.css('li.authors').text
            paper.parent_url = url

            paper.fetch
            @csv << paper.to_ary
          end

        rescue => e
          case e
          when OpenURI::HTTPError
            # 404, which means the issue is not exist, so break the issue loop
            break
          when SocketError
            err 'socket error'
            raise e
          else
            raise e
          end
        rescue SystemCallError => e
          if e === Errno::ECONNRESET
            err 'connection reset'
            raise e
          else
            raise e
          end
        end
      end
      # save the info per volume
      csv_out out
    end
  end
end

def usage
  puts "Usage: #{File.basename($0)} [from_volX] [to_volY]"
  exit 1
end

usage unless ! ARGV.empty? and ARGV.length == 2
usage unless ARGV[0].is_i?
usage unless ARGV[1].is_i?

from = ARGV[0].to_i
to = ARGV[1].to_i

# log into https://auth.uq.edu.au/idp first
f = Fetcher.new
f.run(from, to)

