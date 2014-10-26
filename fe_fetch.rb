#!/usr/bin/env ruby

require './base.rb'
require 'uri'
require 'open-uri'
require 'nokogiri'
require 'pp'

URL = 'http://www.sciencedirect.com/science/journal/0304405X'

class Article
  attr_accessor :title, :url, :pages, :authors, :parent_url

  def print
    puts 'title: ' + @title
    puts 'url: ' + @url
    puts @pages
    puts 'authors: ' + @authors
    puts 'parent_url: ' + @parent_url
  end

end

class Fetcher < Base

  def get_doc(url)
    Nokogiri::HTML(open(url).read)
  end

  def run

    (1..114).each do |volume|
      (1..10).each do |issue|
        begin
          url = "#{URL}/#{volume}/#{issue}"
          puts url
          doc = Nokogiri::HTML(open(url).read)
          #pp doc

          doc.css('ol.articleList > li.detail > ul.article').each do |article|
            a = article.css('li.title > h4 > a').first
            title = a.text
            next if title == 'Editorial Board'

            paper = Article.new
            paper.title = title
            paper.url = a['href']
            paper.pages = article.css('li.source > i').text
            paper.authors = article.css('li.authors').text
            paper.parent_url = url
            paper.print
          end

          exit 1
        rescue => e
          case e
          when OpenURI::HTTPError
            # do something
            break
          when SocketError
            # do something else
            err 'something wrong'
          else
            raise e
          end
        rescue SystemCallError => e
          if e === Errno::ECONNRESET
            # do something else
            err 'something wrong'
          else
            raise e
          end
        end
      end
    end
  end
end

# log into https://auth.uq.edu.au/idp first
f = Fetcher.new
f.run

