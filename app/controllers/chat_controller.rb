# frozen_string_literal: true

require "securerandom"

class ChatController < ApplicationController
  def create
    data_params = params.require(:data).permit(attributes: [ :content ], meta: [ :session_uuid ])
    user_message_content = data_params.dig(:attributes, :content)
    session_uuid = request.headers["X-Session-ID"].presence || data_params.dig(:meta, :session_uuid).presence || SecureRandom.uuid

    unless user_message_content.present?
      render_json_api_error("Bad Request", "O atributo 'content' dentro de 'data.attributes' não pode estar vazio.", :bad_request)
      return
    end

    result = ChatProcessorService.new(session_uuid: session_uuid, user_message: user_message_content).call

    if result.success?
      render json: ChatReplySerializer.new(result.data).serializable_hash, status: :ok
    else
      log_and_render_error(
        session_uuid: session_uuid,
        exception: result.error,
        title: Rack::Utils::HTTP_STATUS_CODES[Rack::Utils.status_code(result.status)] || "Error",
        detail: result.message || result.error.message,
        status: result.status
      )
    end

  rescue ActionController::ParameterMissing => e
    render_json_api_error("Bad Request", "Parâmetro obrigatório ausente: #{e.param}", :bad_request)
  rescue => e
    log_and_render_error(
      session_uuid: session_uuid || "unknown",
      exception: e,
      title: "Internal Server Error",
      detail: "Ocorreu um erro interno inesperado antes do processamento.",
      status: :internal_server_error
    )
  end

  private

  def log_and_render_error(session_uuid:, exception:, title:, detail:, status:)
    Rails.logger.error "[ChatController] Error for session #{session_uuid}: #{exception.class} - #{exception.message}"
    unless [  ApiCommunicationError,
              ActionController::ParameterMissing ].include?(exception.class)
      Rails.logger.error exception.backtrace.join("\n") if exception.respond_to?(:backtrace) && exception.backtrace
    end

    render_json_api_error(title, detail, status)
  end

  def render_json_api_error(title, detail, status)
    render json: {
      errors: [
        {
          status: Rack::Utils.status_code(status).to_s,
          title: title,
          detail: detail
        }
      ]
    }, status: status
  end
end
