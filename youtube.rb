require 'httpclient'


class YoutubeChatMessages

    def initialize video_id, google
        @video_id = video_id
        @google = google
        @next_page_token = nil
        @next_poll = Time.new(2000,1,1)
        @c = HTTPClient.new
        renew_token
        get_video_id
    end

    def get_new raw = false

        params = {
            liveChatId: @chat_id,
            # part: 'snippet,authorDetails',
            part: 'id,snippet,authorDetails',
            fields: 'nextPageToken,pollingIntervalMillis,items(snippet/type,authorDetails/displayName,snippet/publishedAt,snippet/textMessageDetails/messageText)',
        }
        params[:pageToken] = @next_page_token if @next_page_token

        body = api_call('liveChat/messages', query: params)
        return [] unless body
        ret = JSON.parse body, symbolize_names: true
        @next_page_token = ret.fetch(:nextPageToken, nil)
        @next_poll = Time.now + ret.fetch(:pollingIntervalMillis, 0)/1000.0
        return ret[:items] if raw

        all = (ret[:items] || []).select do |msg|
            msg[:snippet][:type] == 'textMessageEvent'
        end.map do |msg|
            {
                name: msg[:authorDetails][:displayName],
                time: Time.parse(msg[:snippet][:publishedAt]),
                message: msg[:snippet][:textMessageDetails][:messageText]
            }
        end

        
        if all.size > 0
            msg = all.first[:message]
            last_msg = (@last_message||{})[:message]
            # p [all.size, msg, last_msg, msg == last_msg]
        end
        if all.size > 0 and @last_message and all.first[:message] == @last_message[:message]
            all = all[1..-1]
            @last_message = all.last || @last_message
        elsif all.size > 0
            @last_message = all.last
        end
        all
    end

    def write_chat msg
        method = 'liveChat/messages'

        params = {
            liveChatId: @chat_id,
            part: 'snippet',
        }

        body = {
            snippet: {
                liveChatId: @chat_id,
                type: 'textMessageEvent',
                textMessageDetails: {
                    messageText: msg
                }
            }
        }

        ret = api_call(
            'liveChat/messages',
            query: params,
            method: 'POST',
            body: body.to_json
        )

    end

    def poll_wait_time
        diff = @next_poll - Time.now
        # puts "%.2fs" % diff
        [diff, 0].max
    end

    def renew_token
        @auth_token = @google.get_oauth_token
    end

    def get_video_id
        params = {
            id: @video_id,
            # part: 'snippet,contentDetails,liveStreamingDetails'
            part: 'liveStreamingDetails',
            fields: 'items/liveStreamingDetails/activeLiveChatId'
        }
        j = JSON.parse api_call('videos', query: params), symbolize_names: true
        @chat_id = j[:items][0][:liveStreamingDetails][:activeLiveChatId]
        p @chat_id
        raise "No chat id" unless @chat_id
    end

    def api_call api, method: 'GET', query: nil, body: nil
        tries = 0
        begin
            url = 'https://www.googleapis.com/youtube/v3/%s?key=%s' % [
                api, @google.api_key
            ]
            headers = {
                'Authorization': "Bearer #{@auth_token}",
                'Content-Type': 'application/json',
            }
            r = @c.request method, url, query, body, headers
            if r.code >= 400
                puts "Error #{r.code}: #{r.body}"
                raise '401' if r.code == 401
                return nil
            end
            r.body
        rescue RuntimeError => e
            tries += 1
            if e.message == '401' and tries <= 3
                renew_token
                retry
            end
        end
    end
end


