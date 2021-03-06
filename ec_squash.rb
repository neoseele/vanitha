#!/usr/bin/env ruby

require 'date'
require 'time'
require 'pp'
require 'csv'
require 'logger'

class Time
  def to_str
    strftime('%H:%M:%S:%L')
  end
end

class Entry
  attr_accessor :no_words,:no_questions,:no_words_having_questions,:start_time,:end_time
  attr_reader :ticker,:ca

  def initialize(row)
    @ticker = row[0]
    @date = row[1]
    @reason = row[3]
    @ca = row[4]
    @first_nm = row[5]
    @surname = row[6]
    @affln = row[7]
    @firm = row[8]
    @jobt = row[9]
    @no_words = row[10].to_i
    @no_questions = row[11].to_i
    @no_words_having_questions = row[12].to_i
    @start_time = Time.parse(row[13].sub(/:(\d+)$/,'.\1'))
    @end_time = Time.parse(row[14].sub(/:(\d+)$/,'.\1'))

    @call_date = Date.parse(@date).strftime("%Y%m%d")
  end

  def full_name
    "#{@first_nm} #{@surname}"
  end

  def =~(b)
    @ticker == b.ticker and @ca == b.ca and full_name == b.full_name
  end

  def merge(b)
    @no_words += b.no_words
    @no_questions += b.no_questions
    @no_words_having_questions += b.no_words_having_questions
  end

  def to_a
    [@ticker,@date,@reason,@ca,@first_nm,@surname,@affln,@firm,@jobt,@no_words,@no_questions,@no_words_having_questions,@call_date]
  end
end

class Qa
  attr_accessor :q, :a, :order, :start_time, :end_time, :is_last

  def initialize(q, order=1, a={})
    @q = q
    @a = a
    @order = order
    @start_time = q.start_time
    @end_time = q.end_time
  end

  def update_end_time e
    @end_time = e.end_time if @end_time < e.end_time
  end
end

### functions

def usage
  puts 'Usage: ' + File.basename(__FILE__) + ' <csv>'
  exit 1
end

def csv_out(content, path)
  CSV.open(path, 'wb') do |csv|
    content.each do |arr|
      csv << arr
    end
  end
end

usage unless ARGV.length == 1 and File.exist?(ARGV[0]) and File.extname(ARGV[0]) == ".csv"

input = ARGV[0]
output_dir = File.dirname(input)
output_file = File.basename(input).sub(/\.csv$/,'_squashed.csv')
output = File.join(output_dir,output_file)

rows = CSV.read(input, {:headers => :false})

qas = []
current_qa = nil
order = 1

rows.each do |r|
  e = Entry.new(r)

  # save the first entry into current_qa
  if current_qa.nil?
    if e.ca == 'A'
      current_qa = Qa.new(e,order)
      qas << current_qa
    end
    next
  end

  q = current_qa.q

  # current entry is from a A
  if e.ca == 'A'
    if e =~ q
      # same ticker and same full_name ? => merge them
      q.merge e

      # increase the qa round's end_time
      current_qa.update_end_time e

      # move onto the next row
      next
    end

    # from this point, either ticker or e's full_name changed
    # either way the current Q&A round is finished

    # increase order if the ticker un-changed
    if e.ticker == q.ticker
      order += 1
    else
      # reset order to 1, flag the ticker's last Q&A
      order = 1
      current_qa.is_last = true
    end

    # create a new qa object
    current_qa  = Qa.new(e,order)
    qas << current_qa

  # current entry is from a C
  else

    # ticker should always matched
    if e.ticker == q.ticker
      a = current_qa.a

      if a.key?(e.full_name)
        # an existing C found in answer hash => merge them
        a[e.full_name].merge e
      else
        # new C found, add it into the answer hash
        current_qa.a[e.full_name] = e
      end

      # increase the qa round's end_time
      current_qa.update_end_time e
    end

  end
end

# flag the dead last Q&A
qas[-1].is_last = true

#pp qas.length

@csv = [['ticker','date','reason','ca','first_nm','surname','affln','firm','jobt','no_words','no_questions','no_words_having_questions','call_date','no_people_respond','order','start_time','end_time','last_one?']]

qas.each do |qa|
  @csv << qa.q.to_a + [qa.a.length,qa.order,qa.start_time.to_str,qa.end_time.to_str,qa.is_last]
  qa.a.values.each do |e|
    @csv << e.to_a
  end
end

## write to csv
puts "* writing results to #{output}"
csv_out(@csv, output)

