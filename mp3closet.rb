require "mp3info"
require "pp"

class Mp3Record

	attr_reader :title, :artist, :album, :filename

	def initialize(title, artist, album, filename)
		@title = title
		@artist = artist
		@album = album
		@filename = filename
	end 

	def asSongName
		"#{@artist} - #{@title}"
	end

	def to_s
		"#{@title}--#{@artist} (#{@album})"
	end

end	

class RecordManager

	attr_reader :records

	def initialize
		@records = []
	end

	def collect(dir) 
		Dir.glob("#{dir}/**/*.mp3")do |item|
			Mp3Info.open(item) do |mp3|
				@records.push(Mp3Record.new(mp3.tag.title, mp3.tag.artist, mp3.tag.album, File.basename(item)))
			end
		end
	end

	def structurize
		collectedItems = Hash.new { |h,k| h[k] = []}
		@records.each do |record|
			collectedItems[record.asSongName()] << record
		end
		pp collectedItems
	end	

end

if ARGV.size != 1
	raise 'Pass dir argument'
end

dir = ARGV[0]
manager = RecordManager.new
manager.collect(dir)
manager.structurize()



