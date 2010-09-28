Gem::Specification.new do |spec|
  spec.name           = 'realityforge-piston'
  spec.version        = Piston::VERSION::STRING
  spec.authors        = ['Francois Beausoleil','Peter Donald']
  spec.email          = ["francois@teksol.info", "peter@realityforge.org"]
  spec.homepage       = "http://github.com/realityforge/piston"
  spec.summary        = "Piston is a utility that eases vendor branch management in subversion."
  spec.description    = <<-TEXT
Piston is a utility that eases vendor branch management in subversion.
  TEXT
  spec.files          = Dir['{contrib,bin,lib,spec}/**/*', '*.gemspec'] +
                        ['LICENSE', 'README.rdoc', 'CHANGELOG', 'Rakefile']
  spec.require_paths  = ['lib']

  spec.bindir = "bin"                               # Use these for applications.
  spec.executables = ["piston"]
  spec.default_executable = "piston"
  
  spec.has_rdoc         = true
  spec.extra_rdoc_files = 'README.rdoc', 'LICENSE', 'CHANGELOG'
  spec.rdoc_options     = '--title', "#{spec.name} #{spec.version}", '--main', 'README.rdoc'
end
