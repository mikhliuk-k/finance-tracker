require 'faraday'
require 'googleauth'

class AiPdfParser
  URL = "https://%{location}-aiplatform.googleapis.com/v1/projects/%{project_id}/locations/%{location}/publishers/google/models/%{model_id}:generateContent"
  LOCATION = 'northamerica-northeast1'
  MODEL_ID = 'gemini-1.5-flash-001'

  BASE_PROMPT = 'Parse the PDF statement and retrieve all transactions in JSON format'
  TEMPERATURE = 0
  MAX_OUTPUT_TOKENS = 8192

  def initialize(project_id:)
    @project_id = project_id
  end

  def parse(storage_path, prompts: [], response_schema:)
    response = client_send(storage_path, response_schema:, prompts:)
    JSON.parse(response.body).dig('candidates', 0, 'content', 'parts', 0, 'text')
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
      Authorization: "Bearer #{auth_token}",
      'Content-Type': 'application/json'
    }

    Faraday.post(url, body.to_json, headers) do |request|
      request.options.timeout = 120
    end
  end

  def auth_token
    Google::Auth::Credentials.default.client.access_token
  end
end
