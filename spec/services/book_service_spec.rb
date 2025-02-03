require 'rails_helper'

RSpec.describe BookService do
  let(:book_id) { '35880' }
  let(:element_id) { 'chapter1' }
  let(:service) { described_class.new(book_id) }

  describe '#fetch_table_of_contents' do
    let(:toc_url) { "https://s3.amazonaws.com/tocs.flatworldknowledge.com/#{book_id}.json" }
    let(:toc_response) { { 'title' => 'Sample Book', 'elements' => [] }.to_json }

    before do
      stub_request(:get, toc_url)
        .to_return(status: 200, body: toc_response, headers: { 'Content-Type' => 'application/json' })
    end

    it 'fetches the table of contents' do
      result = service.fetch_table_of_contents
      expect(result).to include('title' => 'Sample Book')
    end

    it 'memoizes the result' do
      service.fetch_table_of_contents

      expect(WebMock).not_to have_requested(:get, toc_url).twice
    end

    context 'when the API request fails' do
      before do
        stub_request(:get, toc_url).to_return(status: 500)
      end

      it 'raises an APIError' do
        expect { service.fetch_table_of_contents }.to raise_error(BookService::APIError)
      end
    end
  end

  describe '#fetch_book_content' do
    let(:content_url) { "https://scholar.flatworldknowledge.com/api/#{book_id}/elements/#{element_id}" }
    let(:content_response) { { 'content' => 'Chapter content here' }.to_json }

    before do
      stub_request(:get, content_url)
        .to_return(status: 200, body: content_response, headers: { 'Content-Type' => 'application/json' })
    end

    it 'fetches the content for a specific element' do
      result = service.fetch_book_content(element_id)
      expect(result).to include('content' => 'Chapter content here')
    end

    it 'memoizes the result for each element_id' do
      service.fetch_book_content(element_id)

      service.fetch_book_content(element_id)
      expect(WebMock).not_to have_requested(:get, content_url).twice
    end

    it 'makes separate requests for different element_ids' do
      other_element_id = 'chapter2'
      other_content_url = "https://scholar.flatworldknowledge.com/api/#{book_id}/elements/#{other_element_id}"

      stub_request(:get, other_content_url)
        .to_return(status: 200, body: content_response, headers: { 'Content-Type' => 'application/json' })

      service.fetch_book_content(element_id)
      service.fetch_book_content(other_element_id)

      expect(WebMock).to have_requested(:get, content_url).once
      expect(WebMock).to have_requested(:get, other_content_url).once
    end
  end
end
