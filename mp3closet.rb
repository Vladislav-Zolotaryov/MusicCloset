require "mp3info"

if ARGV.size != 1
	raise 'Pass dir argument'
end

dir = ARGV[0]
Dir.glob("#{dir}/**/*.mp3")do |item|
	next if item == '.' or item == '..'
	Mp3Info.open(item, :encoding => 'UTF-8') do |mp3|
		puts mp3.tag.title
		puts mp3.tag.artist
		puts '--->>><<<---'
	end
end

