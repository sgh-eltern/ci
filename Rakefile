# frozen_string_literal: true

require 'rake'
require 'erb'
require 'rake/clean'
require 'pathname'
require 'yaml'
require 'rspec/core/rake_task'

task default: [:spec, :render, "ci:shellcheck"]

RSpec::Core::RakeTask.new

DEPLOYMENT_DIR = 'deployment'.freeze
directory DEPLOYMENT_DIR
CLOBBER.include(DEPLOYMENT_DIR)

TEMPLATE_DIR = Pathname('templates')
TEMPLATES = FileList.new(TEMPLATE_DIR.join('**/*')) do |list|
  list.exclude do |candidate|
    Pathname(candidate).directory?
  end
end

TARGET_FILES = TEMPLATES.pathmap("%{^#{TEMPLATE_DIR},#{DEPLOYMENT_DIR}}p")
CLEAN.include(TARGET_FILES)

TARGET_FILES.each do |target|
  target_dir = Pathname(target).dirname
  template = Pathname(target.pathmap("%{^#{DEPLOYMENT_DIR},#{TEMPLATE_DIR}}p"))

  directory target_dir

  desc "Build #{target} from #{template}"
  file target => [template, target_dir] do
    warn "Rendering #{template} into #{target}"
    File.write(target, ERB.new(template.read).result(binding))
  end
end

desc 'Run shellcheck for generated shell scripts'
task 'shellcheck' => TARGET_FILES do |file|
  sh %(shellcheck deployment/bin/*.sh) do |ok, process_status|
    if !ok
      fail 'The shellcheck findings listed above need to be fixed.'
    end
  end
end

desc 'Render all target files'
task 'render' => TARGET_FILES + [:shellcheck]

desc 'Deploy all files to the Strato box'
task 'deploy' => :render do
  sh 'scp -r deployment/* eltern-sgh.de@ssh.strato.de:'
end

def config
  @config ||= YAML.load_file('config.yml')
end

namespace :ci do
  desc 'Run shellcheck for CI scripts'
  task 'shellcheck' do |file|
    sh %(shellcheck --exclude SC2154 ci/*/task.sh) do |ok, process_status|
      if !ok
        fail 'The shellcheck findings listed above need to be fixed.'
      end
    end
  end
end
