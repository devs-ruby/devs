require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs = ['lib', 'spec', 'test']
  t.test_files = FileList['test/**/*_test.rb'] + FileList['spec/**/*_spec.rb']
end

desc "Run tests"
task :default => [:test]

namespace :example do
  examples = FileList['examples/*.rb']
  examples.each do |fn|
    task_name = fn.split('/').last.split('.').first
    desc "Run #{task_name} example"
    task task_name.to_sym do
      sh "ruby #{fn}"
    end
  end

  desc "Run all examples"
  task :all => examples.map { |fn| fn.split('/').last.split('.').first.to_sym }

  desc "List examples"
  task :list do
    puts "Available examples"
    puts examples.map { |fn| "* #{fn.split('/').last.split('.').first}" }
  end
end
