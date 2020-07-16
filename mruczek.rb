require 'httpclient'
require 'json'

class Mruczek

    attr_accessor :client

    def initialize
        @client = HTTPClient.new
        login
    end

    def insert_question(author, body)
        url = 'http://mruczek.felinae.pl/api/v2.0/question/add'
        headers = {
            'Content-Type' => 'application/json; charset=utf-8'
        }.to_a
        r = client.post(url, { 'author' => author, 'body' => body }.to_json, headers)
        r.body =~ /error/ ? true : false
    end

    def login
        pass = ''
        user = ''
        url = 'http://mruczek.felinae.pl/login'
        client.post(url, { 'username' => user, 'password' => pass })
    end
    
end

if __FILE__ == $0
    m = Mruczek.new
    p m.insert_question('kq', '???')
end
