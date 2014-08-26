# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','entran','version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'entran'
  s.version = Entran::VERSION
  s.author = 'Erik Ordway'
  s.email = 'ordwaye@evergreen.edu'
  s.homepage = 'http://github.com/eriko'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Generate Canvas LMS courses and enrollments'
# Add your other files here if you make them
  s.files = %w(
bin/entran
lib/entran/version.rb
lib/account.rb
lib/boolean.rb
lib/enrollment.rb
lib/section.rb
lib/settings.rb
lib/entran.rb
lib/course.rb
lib/enrollment.rb
lib/term.rb
lib/user.rb
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','entran.rdoc']
  s.rdoc_options << '--title' << 'entran' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'entran'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_development_dependency('pry')
  s.add_development_dependency('pry-byebug')
  s.add_runtime_dependency('gli','2.9.0')
  s.add_runtime_dependency('pandarus')
  s.add_runtime_dependency('faraday')
  s.add_runtime_dependency('faraday_middleware')
  s.add_runtime_dependency('nokogiri')
  s.add_runtime_dependency('zipruby')
  s.add_runtime_dependency('multipart-post')
  s.add_runtime_dependency('powerpack')
  s.add_runtime_dependency('canvas-api','1.0')
  #s.add_runtime_dependency('canvas-api')
end
