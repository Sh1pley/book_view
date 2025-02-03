require "net/http"
require "json"

class BookService
  TOC_BASE_URL = "https://s3.amazonaws.com/tocs.flatworldknowledge.com".freeze
  CONTENT_BASE_URL = "https://scholar.flatworldknowledge.com/books".freeze
  CONTENT_API_URL = "https://scholar.flatworldknowledge.com/api".freeze

class APIError < StandardError; end
  def initialize(book_id)
    @book_id = book_id
  end

  def fetch_table_of_contents
    @table_of_contents ||= begin
      response = make_request("#{TOC_BASE_URL}/#{@book_id}.json")
      parse_response(response)
    end
  end

  def book_content_url_from_id(element_id)
    "#{CONTENT_BASE_URL}/#{@book_id}/#{element_id}/preview"
  end

  def fetch_book_content(element_id)
    # lol.. needs a re-think
    # service.fetch_book_content(el_id)
    # => "<div class=\"ajax-loading\" role=\"alert\"></div>"
    @book_content ||= {}
    @book_content[element_id] ||= begin
      # sniff out the api call to get content!
      # https://scholar.flatworldknowledge.com/api/35880/elements/shapiro_1-31669_2019-06-17_217fb65f2c
      response = make_request("#{CONTENT_API_URL}/#{@book_id}/elements/#{element_id}")
      parse_response(response)
    end
  end

  private

  def make_request(url)
    uri = URI(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request)
    end

    handle_response(response)
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      response
    else
      raise APIError, "Request failed with status: #{response.code} - #{response.message}"
    end
  end

  def parse_response(response)
    JSON.parse(response.body)
  rescue JSON::ParserError, NoMethodError => e
    raise APIError, "Failed to parse response: #{e.message}"
  end
end
