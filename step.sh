#!/bin/bash
set -ex
set +x
set +v

echo "Start Lint Analyze"

echo "Print Enviroments"

echo "  step_repository_url: $step_repository_url"
echo "  step_clone_dir_branch: $step_clone_dir_branch"
echo "  step_branch: $step_branch"

echo "Generate Enviroments"
scripts_dir=$step_clone_dir_branch
file_loc=$swift_lint_report

echo "  scripts_dir: $scripts_dir"
echo "  file_loc: $file_loc"

# ステップのリポジトリをクローンする
echo "Prepare Scripts file, with Git Clone. Dir: $scripts_dir"
if [ -d "$scripts_dir" ]; then
  echo "Directory '$scripts_dir' already exists."
else
  echo "Cloning branch '$step_branch' from repository '$step_repository_url' to directory '$scripts_dir'..."
  git clone -b $step_branch $step_repository_url $scripts_dir
fi
echo "Prepared Scripts file."

# 環境変数を設定する
envman add --key LINT_XML_OUTPUT --value ${file_loc}

# rubyを実行する
ruby ./${scripts_dir}/ruby/ios-lint.rb

echo "Complete Lint Analyze"