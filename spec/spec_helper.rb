require 'simplecov'
require 'coveralls'

# On Ruby 1.9+ use SimpleCov and publish to Coveralls.io
if !RUBY_VERSION.start_with? '1.8'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start do
    add_filter '/spec/'    # exclude test code
    add_filter '/vendor/'  # exclude gems which are vendored on Travis CI
  end
end

lib_dir = File.join(File.dirname(File.dirname(__FILE__)), 'lib')
$LOAD_PATH.unshift lib_dir unless $LOAD_PATH.include? lib_dir

require 'rspec'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
