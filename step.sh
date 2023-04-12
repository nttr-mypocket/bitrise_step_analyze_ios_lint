#!/bin/bash

# Copyright © 2023 NTT Resonant Technology Inc. All Rights Reserved.

set -ex
set +x
set +v

swiftlint_report_name="swiftlint_report"

set +e
echo "Run SwiftLint XML"
swiftlint lint --quiet --reporter checkstyle > ${swiftlint_report_name}.xml
envman add --key LINT_XML_OUTPUT --value "${swiftlint_report_name}.xml"
export LINT_XML_OUTPUT="${swiftlint_report_name}.xml"

if [ "$create_html" = "yes" ]; then
  echo "Run SwiftLint HTML"
  swiftlint lint --quiet --reporter html > ${swiftlint_report_name}.html
  envman add --key LINT_HTML_OUTPUT --value "${swiftlint_report_name}.html"
  export LINT_HTML_OUTPUT="${swiftlint_report_name}.html"
else
  echo "SwiftLint HTML is skipped."
fi
set -e

echo "Print Environments"
echo "  step_repository_url: $step_repository_url"
echo "  step_clone_dir_branch: $step_clone_dir_branch"
echo "  step_branch: $step_branch"

echo "Generate Environments"
scripts_dir=$step_clone_dir_branch

echo "  scripts_dir: $scripts_dir"
echo "  file_loc: ${swiftlint_report_name}.xml"

# ステップのリポジトリをクローンする
echo "Prepare Scripts file, with Git Clone. Dir: $scripts_dir"
if [ -d "$scripts_dir" ]; then
  echo "Directory '$scripts_dir' already exists."
else
  echo "Cloning branch '$step_branch' from repository '$step_repository_url' to directory '$scripts_dir'..."
  git clone -b "$step_branch" "$step_repository_url" "$scripts_dir"
fi
echo "Prepared Scripts file."

# rubyを実行する
echo "Start Lint Analyze"
ruby ./"${scripts_dir}"/ruby/ios_lint.rb

echo "Complete Lint Analyze"