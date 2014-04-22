$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'results/version'

Gem::Specification.new do |s|
  s.name        = 'results'
  s.version     = Results::VERSION
  s.author      = 'Marc Siegel'
  s.email       = 'marc@usainnov.com'
  s.homepage    = 'http://ms-ati.github.com/results/'
  s.summary     = 'Results provides easy composition of Good and Bad results'
  s.description = 'Results is a functional combinator of results which are either Good or Bad inspired by ScalaUtils\'s Or and Every classes'
  s.license     = 'MIT'

  s.rubyforge_project = 'results'

  # Assembles gem files via git commands
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)

  # Adds runtime dependencies
  s.add_dependency 'rescuer', '~> 0.1.0'

  # Runs rspec tests from rake
  s.add_development_dependency 'rake',  '~> 10.3.0'
  s.add_development_dependency 'rspec', '3.0.0.beta2'

  # Generates yard documentation
  if !(defined?(RUBY_ENGINE) && 'jruby' == RUBY_ENGINE)
    # Github flavored markdown in YARD documentation
    # http://blog.nikosd.com/2011/11/github-flavored-markdown-in-yard.html
    s.add_development_dependency 'yard'
    s.add_development_dependency 'redcarpet'
    s.add_development_dependency 'github-markup'
  end

  # Coveralls test coverage tool
  s.add_development_dependency 'coveralls'
end