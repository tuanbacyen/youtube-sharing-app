require "net/http"
require "json"
require "cgi"

class YoutubeOembedService
  OEMBED_URL = "https://www.youtube.com/oembed"
  YOUTUBE_REGEX = /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})/

  def self.extract_id(url)
    url.to_s.match(YOUTUBE_REGEX)&.captures&.first
  end

  def self.fetch(youtube_url)
    uri = URI("#{OEMBED_URL}?url=#{CGI.escape(youtube_url)}&format=json")
    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    { title: data["title"], description: data["author_name"] }
  rescue StandardError
    nil
  end
end
