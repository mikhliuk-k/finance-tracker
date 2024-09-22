require 'csv'
require "functions_framework"
require 'google/cloud/storage'

class App
  PROJECT_ID = 'finances-426618'
  HEADERS = %i[date bank account description balance currency]
  BUCKET_NAME = 'finance-statements'
  REPORT_PATH = 'pivot_report.csv'

  def initialize
    @google_storage = Google::Cloud::Storage.new(project_id: PROJECT_ID)
  end

  def build_pivot
    pivot_table = []

    files = @google_storage.bucket(BUCKET_NAME).files(match_glob: '{RBC,CIBC}/**/*.csv')
    accounts = []

    files.each do |file|
      CSV.parse(file.download.read, headers: true, converters: :numeric, header_converters: :symbol).each do |csv_row|
        bank_name, account_name, _ = Pathname.new(file.name).each_filename.to_a
        accounts |= [account_name]

        pivot_table << [
          csv_row[:date],
          bank_name,
          account_name,
          csv_row[:description],
          csv_row[:balance],
          csv_row[:currency]
        ]
      end
    end

    pivot_table.sort_by! { |date, *_| date }

    balance_by_account = accounts.each_with_object({}) { |account, hash|  hash[account] = 0 }

    pivot_table.map! do |date, bank_name, account_name, description, balance, currency|
      balance_by_account[account_name] = balance

      [
        date,
        bank_name,
        account_name,
        description,
        balance,
        currency,
        *balance_by_account.values,
        balance_by_account.values.sum
      ]
    end

    report = CSV.generate do |csv|
      csv << (HEADERS + accounts + ['Total'])
      pivot_table.each { csv << _1 }
    end

    # noinspection RubyMismatchedArgumentType
    @google_storage.bucket(BUCKET_NAME).create_file(StringIO.new(report), REPORT_PATH)
  end
end

FunctionsFramework.http "build_pivot" do
  App.new.build_pivot
  'OK'
end
