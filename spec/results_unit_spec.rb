require 'spec_helper'
require 'results'

describe Results do

  ##
  # Construct indirectly by wrapping a block which may raise an exception
  ##
  describe '.new' do

    context 'when block does *not* raise' do
      subject { Results.new { 1 } }
      it { is_expected.to eq Results::Good.new(1) }
    end

    context 'with defaults' do
      context 'when block raises ArgumentError' do
        subject { Results.new { Integer('abc') } }
        it { is_expected.to be_a Results::Bad }
      end

      context 'when block raises StandardError' do
        subject { lambda { Results.new { raise StandardError.new('a message') } } }
        it { is_expected.to raise_error(StandardError, 'a message') }
      end
    end

  end

  ##
  # Construct directly by wrapping an existing Rescuer::Success or Rescuer::Failure
  ##
  describe '.from_rescuer' do

    context 'when success' do
      let(:success) { Rescuer::Success.new(1) }
      subject { Results.from_rescuer(success) }
      it { is_expected.to eq Results::Good.new(1) }
    end

    context 'when failure' do
      let(:failure) { Rescuer::Failure.new(StandardError.new('failure message')) }
      subject { Results.from_rescuer(failure) }
      it { is_expected.to eq Results::Bad.new('failure message') }
    end

  end

  ##
  # Transform exception messages via to configured lambdas
  ##
  describe '.transform_exception_message' do

    context 'with defaults' do
      context 'when argument error due to invalid integer' do
        subject { Results.transform_exception_message(begin; Integer('abc'); rescue => e; e; end) }
        it { is_expected.to match /invalid (value|string) for integer(: "abc")?/ } # format varies on MRI, jruby, rbx
      end

      context 'when argument error due to invalid float' do
        subject { Results.transform_exception_message(begin; Float('abc'); rescue => e; e; end) }
        it { is_expected.to match /invalid (value|string) for float(: "abc")?/ }   # format varies on MRI, jruby, rbx
      end
    end

  end

  ##
  # Construct directly as Good
  ##
  describe Results::Good do
    let(:good) { Results::Good.new(1) }

    describe '#when' do
      context 'with true predicate' do
        subject { good.when('dummy') { |_| true } }
        it { is_expected.to be good }
      end

      context 'with false predicate and string error message' do
        subject { good.when('predicate failed') { |_| false } }
        it { is_expected.to eq Results::Bad.new('predicate failed') }
      end

      context 'with false predicate and callable error message' do
        subject { good.when(lambda { |v| "predicate failed for: #{v}" }) { |_| false } }
        it { is_expected.to eq Results::Bad.new('predicate failed for: 1') }
      end
    end

    describe '#when_not' do
      context 'with false predicate' do
        subject { good.when_not('dummy') { |_| false } }
        it { is_expected.to be good }
      end

      context 'with true predicate and string error message, prepends "not"' do
        subject { good.when_not('evaluated as false') { |_| true } }
        it { is_expected.to eq Results::Bad.new('not evaluated as false') }
      end

      context 'with failing predicate and callable error message' do
        subject { good.when_not(lambda { |v| "was not false: #{v}" }) { |_| true } }
        it { is_expected.to eq Results::Bad.new('was not false: 1') }
      end
    end

    describe '#validate' do
      context 'with return of good' do
        subject { good.validate { |_| good } }
        it { is_expected.to be good }
      end

      context 'with return of bad' do
        subject { good.validate { |v| Results::Bad.new("no good: #{v}") } }
        it { is_expected.to eq Results::Bad.new('no good: 1') }
      end
    end

  end

  ##
  # Construct directly as Bad
  ##
  describe Results::Bad do
    let(:bad) { Results::Bad.new('epic fail') }

    describe '#when' do
      context 'with any predicate' do
        subject { bad.when('dummy') { |_| true } }
        it { is_expected.to be bad }
      end
    end

    describe '#when_not' do
      context 'with any predicate' do
        subject { bad.when_not('dummy') { |_| true } }
        it { is_expected.to be bad }
      end
    end

    describe '#validate' do
      context 'with any function' do
        subject { bad.validate { |_| Result::Good.new(2) } }
        it { is_expected.to be bad }
      end
    end

  end

end
