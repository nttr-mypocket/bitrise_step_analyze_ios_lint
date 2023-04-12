# Copyright © 2023 NTT Resonant Technology Inc. All Rights Reserved.

# frozen_string_literal: true

require 'rexml/document'
require 'logger'

# ファイルとエラーの情報を持つ構造体を定義
FileData = Struct.new(
  :file_name,
  :errors
)

# エラーの情報を持つ構造体を定義
ErrorData = Struct.new(
  :line_number,
  :column_number,
  :severity,
  :error_message,
  :source
)

# エラーのカウントを出力する関数
def print_error_counts(logger, error_count, warning_count, other_count)
  logger.info("error count : #{error_count}")
  logger.info("warning count : #{warning_count}")
  logger.info("other count : #{other_count}")
end

# ロガーを設定する
logger = Logger.new($stderr)

# Lintの出力ファイルを取得する
xml_file = ENV["LINT_XML_OUTPUT"]
logger.info("INPUT XML: #{xml_file}")

# エラーの種類ごとにカウントするための変数を初期化する
error_count = 0
warning_count = 0
other_count = 0

# Lintの出力ファイルをパースして問題を取得する
begin
  doc = REXML::Document.new(File.open(xml_file))
  doc.elements.each('//checkstyle/file') do |file_element|
    error_list = []

    # エラーの情報を取得する
    file_element.elements.each('error') do |error_element|
      error_data = ErrorData.new(
        error_element['line'],
        error_element['column'],
        error_element['severity'],
        error_element['message'],
        error_element['source']
      )

      error_list << error_data

      # エラーの数をカウントする
      if error_data.severity.casecmp('warning').zero?
        warning_count += 1
      elsif error_data.severity.casecmp('error').zero?
        error_count += 1
      else
        other_count += 1
      end
    end

    # ファイルごとのエラーの情報を構造体に格納する
    file_issue = FileData.new(
      file_element['name'],
      error_list
    )

    logger.info("converted : #{file_issue}")
  end
rescue StandardError => e
  logger.error("Failed to open XML file : #{xml_file}; error : #{e.message}")
  exit(1)
end

print_error_counts(logger, error_count, warning_count, other_count)

# エラーの数を環境変数に設定する
system("envman add --key LINT_OUTPUT_ERROR --value #{error_count}")
system("envman add --key LINT_OUTPUT_WARNING --value #{warning_count}")
system("envman add --key LINT_OUTPUT_OTHERS --value #{other_count}")

# エラーの数に応じて終了コードを設定する
if error_count.positive? && ENV["fail_on_error"] == "yes"
  logger.error("Critical error count : #{error_count}")
  logger.info("Throwing error in order to fail the build.")
  exit(2)
elsif error_count.positive?
  logger.info("Critical error count : #{error_count}")
  logger.info("Keeping the build alive.")
else
  logger.info("No error has been found.")
end
