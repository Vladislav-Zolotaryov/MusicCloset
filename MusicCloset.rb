require 'taglib'
require 'pp'
require 'fileutils'

class Mp3Record
  attr_reader :title, :artist, :album, :file, :tags
  attr_writer :tags

  def initialize(title, artist, album, file)
    @title = title
    @artist = artist
    @album = album
    @file = file
    @tags = []
  end

  def as_song_name
    if @artist.to_s.empty? && @title.to_s.empty?
      File.basename(@file)
    else
      "#{@artist} - #{@title}"
    end
  end

  def to_s
    if @artist.to_s.empty? && @title.to_s.empty?
      File.basename(@file)
    else
      "#{@title}--#{@artist} (#{@album})"
    end
  end
end

class RecordCollector
  def initialize
    @music_formats = %w(mp3 flac acc ogg mpeg wav)
  end

  def collect(dir)
    records = []
    @music_formats.each do |format|
      Dir.glob("#{dir}/**/*.#{format}") do |item|
        TagLib::FileRef.open(item) do |refFile|
          tag = refFile.tag
          if tag.nil?
            puts('Cannot determine TAG info for ' + item)
            records.push(Mp3Record.new(nil, nil, nil, item))
          else
            records.push(Mp3Record.new(tag.title, tag.artist, tag.album, item))
          end
        end
      end
    end
    records
  end
end

class RecordTagger
  def initialize(records)
    @records = records
    @live_keywords = ['[live]', '(live)']
  end

  def tag
    @records.each do |record|
      next unless @live_keywords.any? do |word|
        (!record.title.nil? && record.title.downcase.include?(word)) || File.basename(record.file).downcase.include?(word)
      end
      record.tags << 'live'
    end
    @records
  end
end

class RecordAggregator
  def initialize(records)
    @records = records
  end

  def aggregate
    aggregatedValues = Hash.new { |h, k| h[k] = [] }
    @records.each do |record|
      aggregatedValues[record.as_song_name] << record
    end
    aggregatedValues
  end
end

class RecordNameResolver
  def replace_illegal_characters(text)
    text.gsub(/[^\w\s]/, '')
  end

  def artist(record)
    artist = record.artist
    if artist.nil? || artist.empty?
      'undefined'
    else
      replace_illegal_characters(record.artist).strip.squeeze(' ')
    end
  end

  def filename(record)
    name_parts = []
    name_parts.push(record.artist.to_s)
    name_parts.push(record.title.to_s)

    name_parts.map! { |e| replace_illegal_characters(e).strip.squeeze(' ') }
    name_parts.select! { |x| !x.empty? }

    if !name_parts.empty?
      name_parts.join(' - ')
    else
      File.basename(record.file, File.extname(record.file))
    end
  end
end

class RecordPathResolver
  def initialize(name_resolver)
    @name_resolver = name_resolver
  end

  def path(record)
    path = ''
    path += @name_resolver.artist(record)
    path += '/live' if record.tags.include?('live')
    path
  end
end

class RecordOrginizer
  def initialize(records, name_resolver, record_path_resolver)
    @records = records
    @name_resolver = name_resolver
    @record_path_resolver = record_path_resolver
  end

  def organize(output_dir)
    @records.each do |record|
      records_path = "#{output_dir}/#{@record_path_resolver.path(record)}"
      FileUtils.mkpath records_path

      filename = @name_resolver.filename(record)
      extension = File.extname(record.file)

      destination = "#{records_path}/#{filename}#{extension}"
      puts(destination)
      FileUtils.cp(record.file, destination)
    end
  end
end

class RecordManager
  def collect(input_dir)
    @records = RecordCollector.new.collect(input_dir)
    self
  end

  def tag
    tagger = RecordTagger.new(@records)
    @records = tagger.tag
    self
  end

  def organize(output_dir)
    record_name_resolver = RecordNameResolver.new
    RecordOrginizer.new(@records, record_name_resolver, RecordPathResolver.new(record_name_resolver)).organize(output_dir)
    self
  end
end

raise 'Pass input and output dirs as arguments' if ARGV.size != 2

input_dir = ARGV[0]
input_dir = input_dir.chop if input_dir[-1] == '/'

output_dir = ARGV[1]
output_dir = output_dir.chop if output_dir[-1] == '/'

manager = RecordManager.new
manager.collect(input_dir).tag.organize(output_dir)
