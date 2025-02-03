class BooksController < ApplicationController
  rescue_from BookService::APIError, with: :handle_api_error

  def toc
    @book_id = params[:book_id]
    @table_of_contents = book_service.fetch_table_of_contents

    respond_to do |format|
      format.html
      format.json { render json: @table_of_contents }
    end
  rescue BookService::APIError => e
    flash.now[:error] = "Unable to load table of contents"
    handle_api_error(e)
  end

  def section
    @book_id = params[:book_id]
    @element_id = params[:element_id]
    @preview_url = "#{BookService::CONTENT_BASE_URL}/#{@book_id}/#{@element_id}/preview"
    @section_data = book_service.fetch_book_content(@element_id)

    respond_to do |format|
      format.html
      format.json { render json: book_service.fetch_book_content(@element_id) }
    end
  end

  private

  def book_service
    @book_service ||= BookService.new(@book_id)
  end

  def handle_api_error(exception)
    Rails.logger.error("API Error: #{exception.message}")
    respond_to do |format|
      format.html { render :error, status: :service_unavailable }
      format.json { render json: { error: exception.message }, status: :service_unavailable }
    end
  end
end
