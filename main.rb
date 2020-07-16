#!/usr/bin/ruby

require_relative 'oauth'
require_relative 'youtube'
require_relative 'mruczek'

YT_ID = 'o1iiqIWRqZQ'

G = Google.new
YT = YoutubeChatMessages.new YT_ID, G
M = Mruczek.new
MIN_POLL_DELAY = 15
# MIN_TIME = Time.parse '2020-05-13 18:35:28 UTC'
MIN_TIME = Time.now - 0
loop do
    arr = YT.get_new
    arr.each do |x|
        puts '%{time}> %{name}: %{message}' % x
        if x[:message] =~ /^!q (.*)/ and x[:time] > MIN_TIME
            q = $1
            M.insert_question "YT #{x[:name]}", q
            YT.write_chat '%{name}: question added' % x
        end
    end
    sleep_time = [YT.poll_wait_time, MIN_POLL_DELAY].max
    if sleep_time > MIN_POLL_DELAY
        puts 'Sleeping for %.2fs' % sleep_time
    end
    sleep sleep_time
end
