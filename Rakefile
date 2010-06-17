require 'rubygems'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'
require 'spec/rake/spectask'
require File.join(File.dirname(__FILE__), 'lib', 'piston', 'version')

PKG_BUILD     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
PKG_NAME      = 'piston'
PKG_VERSION   = Piston::VERSION::STRING + PKG_BUILD
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

RELEASE_NAME  = "REL #{PKG_VERSION}"

RUBY_FORGE_PROJECT = "piston"
RUBY_FORGE_USER    = "fbos"

task :default => :specs

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.summary = "Piston is a utility that enables merge tracking of remote repositories."
  s.description = %q{This is similar to svn:externals, except you have a local copy of the files, which you can modify at will.  As long as the changes are mergeable, you should have no problems.}

  s.bindir = "bin"                               # Use these for applications.
  s.executables = ["piston"]
  s.default_executable = "piston"

  s.files = [ "CHANGELOG", "README", "LICENSE", "Rakefile" ] + FileList["{contrib,bin,spec,lib}/**/*"].to_a

  s.require_path = 'lib'
  s.has_rdoc = false

  s.author = "Francois Beausoleil"
  s.email = "francois@teksol.info"
  s.homepage = "http://piston.rubyforge.org/"
  s.rubyforge_project = "piston"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

desc "Publish the release files to RubyForge."
task :release => [ :package ] do
  `rubyforge login`

  for ext in %w( gem tgz zip )
    release_command = "rubyforge add_release #{PKG_NAME} #{PKG_NAME} 'REL #{PKG_VERSION}' pkg/#{PKG_NAME}-#{PKG_VERSION}.#{ext}"
    puts release_command
    system(release_command)
  end
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('specs') do |t|
  t.spec_files = FileList['specs/**/*.rb']
end
