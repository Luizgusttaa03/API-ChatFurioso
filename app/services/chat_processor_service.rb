# frozen_string_literal: true

require "ostruct"

class ChatProcessingError < StandardError; end
class DatabaseError < ChatProcessingError; end
class ApiCommunicationError < ChatProcessingError; end

class ChatProcessorService
  MAX_HISTORY_TURNS = 5

  FURIA_PERSONA_INSTRUCTION = <<~PROMPT.strip
    Você é o ChatFurioso, um chatbot super fã da FURIA Esports e de jogos eletronicos. Sua paixão é contagiante!
    Você adora falar sobre CS2, Valorant, LoL, Rocket League, R6 e qualquer outra modalidade onde a FURIA compete.
    Conhece os jogadores (atuais e históricos), as maiores conquistas, jogadas icônicas e até os memes da torcida.
    Responda sempre com entusiasmo, bom humor e use gírias de torcedor brasileiro (mas sem exagerar).
    Se não souber algo, admita com humildade, mas sempre puxe para um lado positivo da FURIA.
    Seu objetivo é engajar o usuário e celebrar a FURIA!
  PROMPT

  attr_reader :session_uuid, :user_message, :chat_session

  def initialize(session_uuid:, user_message:)
    @session_uuid = session_uuid
    @user_message = user_message
    @chat_session = find_or_create_session # Find/create session during initialization
  end

  def call
    history = load_history
    response_text = generate_response(history)
    save_turn(response_text)

    OpenStruct.new(success?: true, data: { reply: response_text, session_uuid: chat_session.uuid, history: history })

  rescue DatabaseError, ApiCommunicationError => e
    status = e.is_a?(ApiCommunicationError) ? :service_unavailable : :internal_server_error
    OpenStruct.new(success?: false, error: e, status: status)
  rescue => e
    Rails.logger.error "[ChatProcessorService] Unexpected error for session UUID #{chat_session&.uuid || 'new'}: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    OpenStruct.new(success?: false, error: e, status: :internal_server_error, message: "Erro inesperado no processamento do chat.")
  end

  private

  def find_or_create_session
    session = if session_uuid.present?
                ChatSession.find_or_create_by!(uuid: session_uuid)
    else
                ChatSession.create!
    end
    session
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.error "[ChatProcessorService] Database error finding/creating session (UUID: #{session_uuid || 'new'}): #{e.message}"
    raise DatabaseError, "Erro ao encontrar ou criar sessão: #{e.message}"
  end

  def load_history
    chat_session.chat_messages
                .order(:created_at)
                .last(MAX_HISTORY_TURNS * 2)
                .map { |msg| { role: msg.role, text: msg.content } }
  end

  def generate_response(history)
    response_text = GeminiService.generate_text(
      current_prompt: user_message,
      history: history,
      system_instruction: FURIA_PERSONA_INSTRUCTION
    )

    if response_text.blank? && response_text != ""
      Rails.logger.warn("[ChatProcessorService] GeminiService returned blank response for session #{chat_session.uuid}")
      "Não consegui pensar em uma resposta para isso agora, mas VAMO FURIA! 🐾"
    else
      response_text
    end
  rescue GeminiApiError => e
    raise ApiCommunicationError, e.message
  end

  def save_turn(response_text)
    ActiveRecord::Base.transaction do
      chat_session.chat_messages.create!(role: "user", content: user_message)
      chat_session.chat_messages.create!(role: "model", content: response_text)
    end
  rescue ActiveRecord::RecordInvalid => e
    raise DatabaseError, "Não foi possível salvar a mensagem da conversa: #{e.message}"
  end
end
