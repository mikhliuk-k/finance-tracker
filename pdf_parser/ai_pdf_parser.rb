require 'faraday'
require 'googleauth'

require_relative 'credentials'

class AiPdfParser
  URL = "https://%{location}-aiplatform.googleapis.com/v1/projects/%{project_id}/locations/%{location}/publishers/google/models/%{model_id}:generateContent"
  LOCATION = 'northamerica-northeast1'
  MODEL_ID = 'gemini-1.5-flash-001'

  BASE_PROMPT = 'Parse the PDF statement and retrieve all transactions'
  TEMPERATURE = 0
  MAX_OUTPUT_TOKENS = 8192

  def initialize
    @credentials = Credentials.default
    @project_id = 'finances-426618'
    @auth_token = Google::Auth::Credentials.default.client.access_token
  end

  def parse(storage_path, prompts: [], response_schema:)
    client_send(storage_path, response_schema:, prompts:).
      then { |response| JSON.parse(response.body, symbolize_names: true) }.
      tap { |response| raise response.fetch(:error).fetch(:message) if response.has_key?(:error) }.
      then { |response| [:candidates, 0, :content, :parts, 0, :text].inject(response) { |resp, key| resp.fetch(key) } }
  end

  private

  def client_send(storage_path, response_schema:, prompts: [])
    url = URL % { location: LOCATION, project_id: @project_id, model_id: MODEL_ID }

    body = {
      contents: {
        role: 'model',
        parts: [
          { fileData: { mimeType: 'application/pdf', fileUri: storage_path } },
          { text: ([BASE_PROMPT] + prompts).join("\n") }
        ]
      },
      generationConfig: {
        temperature: TEMPERATURE,
        maxOutputTokens: MAX_OUTPUT_TOKENS,
        responseMimeType: 'application/json',
        responseSchema: response_schema
      }
    }

    headers = {
      Authorization: "Bearer #{@auth_token}",
      'Content-Type': 'application/json'
    }

    Faraday.post(url, body.to_json, headers) do |request|
      request.options.timeout = 120
    end
  end
end
