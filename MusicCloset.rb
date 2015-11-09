require "taglib"
require "pp"
require 'fileutils'

class Mp3Record

	attr_reader :title, :artist, :album, :file

	def initialize(title, artist, album, file)
		@title = title
		@artist = artist
		@album = album
		@file = file
	end 

	def asSongName
		"#{@artist} - #{@title}"
	end

	def to_s
		"#{@title}--#{@artist} (#{@album})"
	end

end	

class RecordManager

	def collect(dir) 
		records = []
		Dir.glob("#{dir}/**/*.mp3") do |item|
			TagLib::FileRef.open(item) do |refFile|
				tag = refFile.tag
				records.push(Mp3Record.new(tag.title, tag.artist, tag.album, item))
			end
		end
		records
	end

	def aggregate(records)
		aggregatedValues = Hash.new { |h,k| h[k] = [] }
		records.each do |record|
			aggregatedValues[record.asSongName()] << record
		end
		aggregatedValues
	end	
	
	def organize(aggregatedValues, dir)
		aggregatedValues.each do |key, records|
			firstRecord = records.first
			recordsPath = "#{dir}#{firstRecord.artist.to_s.gsub '/', ''}/"
			downcaseTitle = firstRecord.title.to_s.downcase
			if downcaseTitle.include? "[live]" or downcaseTitle.include? "(live)"
				recordsPath += "live/"
			end
			FileUtils.mkpath recordsPath	
			records.each_with_index do |record, index|
				artist = record.artist.to_s.gsub '/', ''
				title = record.title.to_s.gsub '/', ''

				destination = recordsPath + "#{artist} - #{title}"
				if records.size > 1
					destination += " D[#{index}]"
				end
				destination += "#{File.extname(record.file)}"
				FileUtils.cp(record.file, destination)
			end
		end
	end

end

if ARGV.size != 2
	raise 'Pass input and output dirs as arguments'
end

inputDir = ARGV[0]
if inputDir[-1] != "/"
	inputDir += "/"
end

outputDir = ARGV[1]
if outputDir[-1] != "/"
	outputDir += "/"
end

manager = RecordManager.new
manager.organize(manager.aggregate(manager.collect(inputDir)), outputDir)



