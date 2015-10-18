require "mp3info"

class Mp3Record
	
	def initialize(title, artist, album, filename)
		@title = title
		@artist = artist
		@album = album
		@filename = filename
	end 

	def to_s
		"Record: #{@title}--#{@artist} (#{@album}) = #{filename}"
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

end

if ARGV.size != 1
	raise 'Pass dir argument'
end

dir = ARGV[0]
manager = RecordManager.new
manager.collect(dir)

p manager.records


