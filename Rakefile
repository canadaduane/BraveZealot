require 'rake'
require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Run the test suite.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/test_*.rb'
  t.verbose = true
end

rule "" do |t|
  # test:file:method
  if /test:(.*)(:([^.]+))?$/.match(t.name)
    arguments = t.name.split(":")[1..-1]
    file_name = arguments.first
    test_name = arguments[1..-1] 
    
    if File.exist?("test/test_#{file_name}.rb")
      run_file_name = "test/test_#{file_name}.rb" 
    end
    
    sh "ruby -Ilib:test #{run_file_name} -n /#{test_name}/" 
  end
end