require "mp3info"

if ARGV.size != 1
	raise 'Pass dir argument'
end

dir = ARGV[0]
Dir.glob("#{dir}/**/*")do |item|
	next if item == '.' or item == '..'
	puts item
end

