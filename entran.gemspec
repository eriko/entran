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
  s.add_runtime_dependency('gli','2.5.4')
end
