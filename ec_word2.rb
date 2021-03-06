#!/usr/bin/env ruby

require './base.rb'
require 'time'

# transcript look up table
$transcripts = {}
$word_count = {}

class Transcript
  attr_accessor :reason, :speeches
  def initialize reason
    @reason = reason
    @speeches = []
  end

  def find_speech_by_time(start_time, end_time)
    found = []
    @speeches.each do |s|
      next if s.speaker.downcase == 'operator'
      found << s if s.start_time >= start_time and s.end_time <= end_time
    end
    found
  end

  def find_speech_by_speaker(speaker)
    found = []
    @speeches.each do |s|
      next if s.speaker.downcase == 'operator'
      found << s if s.speaker == speaker
    end
    found
  end

  def self.merge_word_count(speeches, word_count = {})
    while speeches.size > 0
      word_count.merge!(speeches.shift.word_count) { |k,old,new| old + new }
    end
    word_count
  end

  def self.merge_words(speeches, words = '')
    speeches.each do |s|
      words += s.text.gsub(/\r\n?/,'').gsub(/\n/,'')
    end
    words.strip
  end
end

class Speech
  attr_accessor :speaker, :start_time, :end_time, :text, :word_count
  def initialize r
    @speaker = r['Transcript Speaker'].downcase
    @start_time = Time.parse(r['Start Time'].split(' ')[1])
    @end_time = Time.parse(r['End Time'].split(' ')[1])
    @text = r['Transcript Text'].downcase
    cal_word_count
  end

  private

  def cal_word_count
    @word_count = {}
    @text.split(' ').each do |w|
      word = w.downcase.gsub(/\W/, '')
      next unless word != ''

      if @word_count[word].nil?
        @word_count[word] = 1
        next
      end
      @word_count[word] += 1
    end
  end
end

class Jump
  attr_accessor :reason, :full_name, :start_talk_time, :end_talk_time
  def initialize r
    # do not downcase it, transcript's filename is in camel case
    @reason = r['reason']
    @full_name = r['first_nm_up'].downcase + ' ' + r['surname_up'].downcase
    @start_talk_time = Time.parse(r['talk_start_time'])
    @end_talk_time = Time.parse(r['talk_end_time'])
  end
end

class Worker < Base
  attr_accessor :options

  def read_csv path
    CSV.read(path, {headers: true, encoding: 'UTF-8'})
  end

  def run
    src = @options.source
    dir = File.dirname src
    jump = read_csv(src)

    # create the output array
    out = [jump.headers + ['Words Spoken']]

    # loop through each row in jump file
    jump.each do |r|
      j = Jump.new r
      reason = j.reason

      # use the existing one in the lookup table if its available
      if $transcripts.has_key? reason
        t = $transcripts[reason]
      else
        # load the transcript from file
        ec_path = File.join(dir,"#{reason}.csv")

        # skip the row if matching EC transcript is not found
        unless File.exist? ec_path
          err ec_path + ' does not exist'
          next
        end

        t = Transcript.new reason
        read_csv(ec_path).each do |s|
          begin
            t.speeches << Speech.new(s)
          rescue
            # skip this row if anything odd happened parsing this row
            # most likely the start/end time is missing
            next
          end
        end

        # add the transcript to the lookup table
        $transcripts[reason] = t
      end

      #ss = t.find_speech_by_speaker j.full_name
      st = t.find_speech_by_time j.start_talk_time, j.end_talk_time

      out << r.to_hash.merge({'words_spoken' => Transcript.merge_words(st)}).values
      Transcript.merge_word_count(st, $word_count)
    end

    # write the updated jump file
    csv_out File.join(dir,'out.csv'), out

    out_count = [['word','count']]
    $word_count.each do |word,count|
      out_count << [word, count]
    end

    # write the word count
    csv_out File.join(dir, 'out_count.csv'), out_count
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
@opts.on('-s', '--source File', String, 'Require: source') do |o|
  options.source = o if File.exist?(o)
end
@opts.on_tail("-h", "--help", "Show this message") do
  puts @opts
  exit
end
@opts.parse! rescue usage

### main
usage if options.source.nil?

w = Worker.new
w.options = options
w.run
