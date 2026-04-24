require 'rails_helper'

RSpec.describe YoutubeOembedService do
  describe '.extract_id' do
    it 'extracts id from standard URL' do
      expect(YoutubeOembedService.extract_id('https://www.youtube.com/watch?v=dQw4w9WgXcQ')).to eq('dQw4w9WgXcQ')
    end

    it 'extracts id from short URL' do
      expect(YoutubeOembedService.extract_id('https://youtu.be/dQw4w9WgXcQ')).to eq('dQw4w9WgXcQ')
    end

    it 'extracts id from Shorts URL' do
      expect(YoutubeOembedService.extract_id('https://www.youtube.com/shorts/dQw4w9WgXcQ')).to eq('dQw4w9WgXcQ')
    end

    it 'returns nil for non-YouTube URL' do
      expect(YoutubeOembedService.extract_id('https://vimeo.com/123')).to be_nil
    end
  end

  describe '.fetch' do
    let(:url) { 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }

    context 'when oEmbed responds with success' do
      before do
        stub_request(:get, /youtube\.com\/oembed/)
          .to_return(
            status: 200,
            body: { title: 'Rick Astley - Never Gonna Give You Up', author_name: 'Rick Astley' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns title and description' do
        result = YoutubeOembedService.fetch(url)
        expect(result[:title]).to eq('Rick Astley - Never Gonna Give You Up')
        expect(result[:description]).to eq('Rick Astley')
      end
    end

    context 'when oEmbed responds with error' do
      before do
        stub_request(:get, /youtube\.com\/oembed/).to_return(status: 404)
      end

      it 'returns nil' do
        expect(YoutubeOembedService.fetch(url)).to be_nil
      end
    end
  end
end
