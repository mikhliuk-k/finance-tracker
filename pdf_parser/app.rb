require 'csv'
require 'functions_framework'
require 'google/cloud/storage'

require_relative 'ai_pdf_parser'

class App
  PROJECT_ID = 'finances-426618'

  RESPONSE_SCHEMA = {
    type: :array,
    items: {
      type: :object,
      properties: {
        date: { type: :string },
        description: { type: :string },
        withdrawals: { type: :number },
        deposits: { type: :number },
        balance: { type: :number },
        currency: { type: :string, enum: [:CAD, :USD], default: :CAD },
        category: { type: :string }
      },
      required: [:date, :description, :balance, :currency, :category]
    }
  }.freeze

  PROPERTIES = RESPONSE_SCHEMA.fetch(:items).fetch(:properties).keys

  def initialize
    @ai_pdf_parser = AiPdfParser.new(project_id: PROJECT_ID)
    @google_storage = Google::Cloud::Storage.new(project_id: PROJECT_ID)
  end

  def parse_pdf(bucket_name, pdf_file_path)
    transactions = parse_transactions(bucket_name, pdf_file_path)
    csv_file_path = Pathname.new(pdf_file_path).sub_ext('.csv').to_s
    store_transactions(transactions, bucket_name, csv_file_path)
  end

  private

  def parse_transactions(bucket_name, file_path)
    folder_name = folder(file_path)

    if folder_name == 'RBC'
      parse_rbc_statement(bucket_name, file_path)
    else
      raise NotImplementedError.new("Parser for #{folder_name} is not implemented")
    end
  end

  def store_transactions(transactions, bucket_name, file_path)
    csv_file = CSV.generate do |csv|
      csv << PROPERTIES
      transactions.each { |transaction| csv << PROPERTIES.map { |property| transaction[property] } }
    end

    # noinspection RubyMismatchedArgumentType
    @google_storage.bucket(bucket_name).create_file(StringIO.new(csv_file), file_path)
  end

  def parse_rbc_statement(bucket_name, file_path)
    raw_transactions = @ai_pdf_parser.parse(
      "gs://#{bucket_name}/#{file_path}",
      response_schema: RESPONSE_SCHEMA,
      prompts: [
        'There are no category in statement, add category column and fill correct value',
        'Do not include opening and closing balance',
        'Dates should be in the DB format, like YYYY-MM-DD',
        'If dates are missed, fill them up correctly'
      ]
    )

    JSON.parse(raw_transactions, symbolize_names: true)
  end

  def folder(file_name)
    Pathname.new(file_name).each_filename.first
  end
end

FunctionsFramework.cloud_event('parse_pdf') do |event|
  bucket_name = event.data.fetch('bucket')
  folder_name = event.data.fetch('name')
  App.new.parse_pdf(bucket_name, folder_name)
end
