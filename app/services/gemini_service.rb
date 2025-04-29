# frozen_string_literal: true

require "faraday"
require "json"
require "logger"

# Custom error class for Gemini API specific issues
class GeminiApiError < StandardError; end

# Service class to interact with the Google Gemini API
class GeminiService
  MODEL_NAME = "gemini-1.5-flash-latest".freeze
  BASE_API_URL = "https://generativelanguage.googleapis.com".freeze

  # Default generation parameters
  DEFAULT_TEMPERATURE = 0.7
  DEFAULT_TOP_P = 0.9
  DEFAULT_TOP_K = nil

  # Memoized Faraday connection instance
  def self.connection
    @connection ||= Faraday.new(url: BASE_API_URL) do |faraday|
      faraday.adapter Faraday.default_adapter
      faraday.headers["Content-Type"] = "application/json"
      # Set reasonable timeouts
      faraday.options.timeout = 60 # seconds
      faraday.options.open_timeout = 10 # seconds
    end
  end

  # Generates text using the Gemini API based on the current prompt,
  # conversation history, and optional system instructions.
  #
  # @param current_prompt [String] The latest message from the user.
  # @param history [Array<Hash>] An array of previous messages,
  #   each like { role: 'user'/'model', text: '...' }.
  # @param system_instruction [String, nil] Initial instruction for the model's persona.
  # @param temperature [Float] Generation temperature.
  # @param top_p [Float] Generation top_p.
  # @param top_k [Integer, nil] Generation top_k.
  # @return [String, nil] The generated text response or nil if no text was generated.
  # @raise [GeminiApiError] If the API key is missing or API communication fails.
  def self.generate_text(current_prompt:, history: [], system_instruction: nil, temperature: DEFAULT_TEMPERATURE, top_p: DEFAULT_TOP_P, top_k: DEFAULT_TOP_K)
    api_key = ENV["GEMINI_API_KEY"]
    unless api_key
      error_message = "Chave da API GEMINI_API_KEY não configurada no ambiente."
      log_error(error_message)
      raise GeminiApiError, error_message
    end

    contents = build_contents(current_prompt, history, system_instruction)
    generation_config = build_generation_config(temperature, top_p, top_k)

    request_body = {
      contents: contents,
      generationConfig: generation_config
      # safetySettings: [] # Optional: Add safety settings if needed
    }.to_json

    begin
      full_api_url = "/v1beta/models/#{MODEL_NAME}:generateContent?key=#{api_key}"
      response = connection.post(full_api_url) do |req|
        req.body = request_body
      end
      handle_response(response)
    rescue Faraday::TimeoutError => e
      log_error("Timeout ao conectar com a API Gemini: #{e.message}")
      raise GeminiApiError, "Timeout na comunicação com a API: #{e.message}"
    rescue Faraday::ConnectionFailed => e
      log_error("Falha na conexão com a API Gemini: #{e.message}")
      raise GeminiApiError, "Falha na conexão com a API: #{e.message}"
    rescue Faraday::Error => e # Catch other Faraday errors
      log_error("Erro Faraday não especificado: #{e.message} - Response: #{e.response&.body}")
      raise GeminiApiError, "Erro de comunicação com a API: #{e.message}"
    rescue JSON::ParserError => e # Catch JSON parsing errors for the request body (less likely)
      log_error("Erro ao construir JSON da requisição: #{e.message}")
      raise GeminiApiError, "Erro interno ao preparar requisição para API."
    end
  end

  # --- Private Helper Methods ---
  private_class_method

  # Builds the 'contents' array for the Gemini API request.
  def self.build_contents(current_prompt, history, system_instruction)
    contents = []
    # Add system instruction as the first user message, followed by a model confirmation
    if system_instruction.present?
      contents << { role: "user", parts: [ { text: system_instruction } ] }
      # This simulated model response helps guide the actual model
      contents << { role: "model", parts: [ { text: "Ok, entendi. Sou um fã da FURIA pronto para conversar!" } ] }
    end

    # Add validated history messages
    history.each do |message|
      if message[:role] && message[:text] && %w[user model].include?(message[:role])
        contents << { role: message[:role], parts: [ { text: message[:text] } ] }
      else
        log_warn("Item de histórico inválido ignorado: #{message.inspect}")
      end
    end

    # Add the current user prompt
    contents << { role: "user", parts: [ { text: current_prompt } ] }
    contents
  end

  # Builds the 'generationConfig' hash.
  def self.build_generation_config(temperature, top_p, top_k)
    {
      temperature: temperature,
      topP: top_p,
      topK: top_k
    }.compact # Removes nil values (like top_k if not provided)
  end

  # Handles the response from the Gemini API.
  def self.handle_response(response)
    unless response
      log_error("Recebida resposta nula do Faraday.")
      raise GeminiApiError, "Erro de comunicação: Resposta da API foi nula."
    end

    if response.success?
      parse_successful_response(response.body)
    else
      handle_failed_response(response)
    end
  end

  # Parses the body of a successful API response.
  def self.parse_successful_response(body)
    begin
      json_body = JSON.parse(body)
      text = json_body.dig("candidates", 0, "content", "parts", 0, "text")

      if text
        text
      else
        handle_response_without_text(json_body, body)
      end
    rescue JSON::ParserError => e
      log_error("Erro ao parsear JSON de resposta bem-sucedida: #{e.message} - Corpo: #{body}")
      raise GeminiApiError, "Erro ao processar resposta da API (JSON inválido)."
    end
  end

  # Handles successful responses that lack the expected text content.
  def self.handle_response_without_text(json_body, original_body)
    finish_reason = json_body.dig("candidates", 0, "finishReason")
    safety_ratings = json_body.dig("candidates", 0, "safetyRatings")
    prompt_feedback = json_body.dig("promptFeedback")

    log_error("Resposta da API Gemini sem conteúdo de texto. FinishReason: #{finish_reason}, SafetyRatings: #{safety_ratings}, PromptFeedback: #{prompt_feedback}. Body: #{original_body}")

    case finish_reason
    when "SAFETY"
      raise GeminiApiError, "A resposta foi bloqueada por motivos de segurança."
    when "RECITATION"
      raise GeminiApiError, "A resposta foi bloqueada por problemas de citação."
    when "OTHER"
      raise GeminiApiError, "A resposta foi interrompida por um motivo não especificado."
    when "STOP"
      # Model stopped normally but produced no text
      ""
    else
      # Unknown reason or missing finishReason
      nil # Or raise GeminiApiError, "Resposta da API em formato inesperado."
    end
  end

  # Handles failed API responses (non-2xx status).
  def self.handle_failed_response(response)
    error_details = parse_error_details(response.body)
    error_message = "Erro na API Gemini (status: #{response.status}): #{error_details || response.body}"
    log_error(error_message)
    raise GeminiApiError, error_message
  end

  # Attempts to parse error details from the response body.
  def self.parse_error_details(body)
    begin
      json_error = JSON.parse(body)
      json_error.dig("error", "message") || json_error.inspect
    rescue JSON::ParserError
      body # Return the original body if it's not valid JSON
    end
  end

  # Logs an error message using Rails logger if available, otherwise standard logger.
  def self.log_error(message)
    logger.error("[GeminiService] #{message}")
  end

  # Logs a warning message.
  def self.log_warn(message)
    logger.warn("[GeminiService] #{message}")
  end

  # Provides a logger instance (Rails logger or standard logger).
  def self.logger
    @logger ||= defined?(Rails) && Rails.logger ? Rails.logger : Logger.new($stdout)
  end
end
