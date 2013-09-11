#!/usr/bin/env ruby

require './base.rb'

class Firm
  attr_accessor :id, :gvkey, :lpermno, :date, :year, :size, :matches
  def initialize(gvkey, date, lpermno, size, year)
    @gvkey = gvkey
    @lpermno = lpermno
    @date = date
    @year = year
    @size = size.to_f
    @id = "#{lpermno}-#{year}"
    @matches = []
  end
  def sort_matches
    @matches.sort_by! { |obj| obj.diff }
  end
  def to_arr
    [@gvkey,@date,@lpermno,@size,@year]
  end
end

class Diff
  attr_accessor :ref_id, :diff
  def initialize(ref_id, diff)
    @ref_id = ref_id
    @diff = diff
  end
end

class Matcher < Base
  def load(file)
    firms = {}
    CSV.read(file, :headers => true, :encoding => 'UTF-8').each do |r|
      f = Firm.new(r[0], r[1], r[2], r[3], r[4])
      firms[f.id] = f
    end
    firms
  end

  def match(source, reference)
    no_match = [['gvkey','date','lpermono','size','year']]

    banks = load(source)
    controls = load(reference)

    banks.values.each do |b|
      info("matching bank(year): #{b.id} ... ")

      controls.values.each do |c|
        if b.year == c.year and b.lpermno != c.lpermno
          diff = (b.size - c.size).abs / b.size
          b.matches << Diff.new(c.id, diff) if diff <= LIMIT
        end
      end

      if b.matches.length == 0
        err("no match found for bank(year): #{b.id} (diff <= #{(LIMIT*100).round}%)")
        no_match << b.to_arr
        next
      end

      # sort the matches by size diff
      b.sort_matches

      b.matches.each do |d|
        c = controls[d.ref_id]
        @csv << [b.gvkey,b.lpermno,b.date,b.year,b.size,c.gvkey,c.lpermno,c.date,c.size,d.diff]
      end
      # remove the best match from the reference table
      controls.delete(b.matches[0].ref_id)
    end

    csv_out('no_match.csv', no_match)
  end
end

def usage
  puts @opts
  exit 1
end

### constants
LIMIT = 0.3

### options
options = OpenStruct.new
@opts = OptionParser.new
@opts.banner = "Usage: #{File.basename($0)} [options]"
@opts.on('-s', "--source FILE", String, 'Require: source file') do |s|
    options.source = s if File.exist?(s)
end
@opts.on('-r', "--reference FILE", String, 'Require: reference file') do |r|
    options.reference = r if File.exist?(r)
end
@opts.on_tail("-h", "--help", "Show this message") do
    puts @opts
    exit
end
@opts.parse! rescue usage

### main
usage if options.source.nil?
usage if options.reference.nil?

m = Matcher.new
m.csv = [["bk_gvkey","bk_permno","bk_date","year","bk_size",
  "ctrl_gvkey","ctrl_permno","ctrl_date","ctrl_size","size_diff"]]
m.match(options.source, options.reference)
m.csv_out 'result.csv'

