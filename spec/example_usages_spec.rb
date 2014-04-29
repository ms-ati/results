require 'spec_helper'
require 'results'

##
# These specs ensure that published usage examples continue to work.
##
describe 'Example usages' do

  def parseAge(str)
    Results.new(str) { |v| Integer(v) }
  end

  describe 'Basic validation' do

    context 'parseAge("1")' do
      subject { parseAge('1').inspect }
      it { is_expected.to eq '#<struct Results::Good value=1>' }
    end

    context 'parseAge("abc")' do
      subject { parseAge('abc').inspect }
      it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="invalid value for integer", input="abc">]>' }
    end

  end

  def parseAge21To45(str)
    # Syntax workaround due to lack of support for chaining on blocks
    a = parseAge(str)
    b = a.when    ('under 45') { |v| v < 45 }
    _ = b.when_not('under 21') { |v| v < 21 }
  end

  under_45 = Results::Filter.new('under 45') { |v| v < 45 }

  under_21 = lambda { |v| v < 21 }.tap { |l| l.define_singleton_method(:message) { 'under 21' } }

  def parseAgeRange(str)
    parseAge(str).validate do |v|
      case v
      when 21...45 then Results::Good.new(v)
      else              Results::Bad.new('not between 21 and 45', v)
      end
    end
  end

  def valid?(str)
    Results.new(str)
      .when_not(Results.predicate :nil?)
      .when_not(Results.predicate :empty?)
  end

  def valid_short?(str)
    Results.new(str)
      .when_not(:nil?)
      .when_not(:empty?)
  end

  describe 'Chained filters and validations' do

    context 'parseAge21To45("29")' do
      subject { parseAge21To45('29').inspect }
      it { is_expected.to eq '#<struct Results::Good value=29>' }
    end

    context 'parseAge21To45("65")' do
      subject { parseAge21To45('65').inspect }
      it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="not under 45", input=65>]>' }
    end

    context 'parseAge21To45("1")' do
      subject { parseAge21To45('1').inspect }
      it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="under 21", input=1>]>' }
    end

    context 'parseAgeRange("29")' do
      subject { parseAgeRange('29').inspect }
      it { is_expected.to eq '#<struct Results::Good value=29>' }
    end

    context 'parseAgeRange("65")' do
      subject { parseAgeRange('65').inspect }
      it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="not between 21 and 45", input=65>]>' }
    end

    context 'parseAge("65").when(under_45).when_not(under_21)' do
      subject { parseAge('65').when(under_45).when_not(under_21).inspect }
      it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="not under 45", input=65>]>' }
    end

    context 'parseAge("16").when(under_45).when_not(under_21)' do
      subject { parseAge('16').when(under_45).when_not(under_21).inspect }
      it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="under 21", input=16>]>' }
    end

    context 'parseAge("65").when(lambda { |v| "#{v} is not under 45" }) { |v| v < 45 }' do
      subject { parseAge('65').when(lambda { |v| "#{v} is not under 45" }) { |v| v < 45 }.inspect }
      it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="65 is not under 45", input=65>]>' }
    end

    context 'Results.when_not(under_21).call(16)' do
      subject { Results.when_not(under_21).call(16).inspect }
      it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="under 21", input=16>]>' }
    end

    context 'valid?(nil)' do
      subject { valid?(nil).inspect }
      it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="nil", input=nil>]>' }
    end

    context 'valid?("")' do
      subject { valid?('').inspect }
      it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="empty", input="">]>' }
    end

    context 'valid_short?(nil)' do
      subject { valid_short?(nil).inspect }
      it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="nil", input=nil>]>' }
    end

  end

  describe 'Accumulating multiple bad results' do

    describe 'Multiple filters and validations of a single input' do

      context 'Results.new(1.23).when(:integer?).and.when(:zero?)' do
        subject { Results.new(1.23).when(:integer?).and.when(:zero?).inspect }
        it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="not integer", input=1.23>, ' +
                                                          '#<struct Results::Because error="not zero", input=1.23>]>' }
      end

    end

  end

end