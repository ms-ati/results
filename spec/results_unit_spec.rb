require 'spec_helper'
require 'results'

describe Results do

  ##
  # Construct indirectly by wrapping a block which may raise an exception
  ##
  describe '.new' do

    context 'with non-callable value' do
      subject { Results.new(1) }
      it { is_expected.to eq Results::Good.new(1) }
    end

    context 'with callable value' do
      context 'when callable does *not* raise' do
        subject { Results.new(lambda { 1 }) }
        it { is_expected.to eq Results::Good.new(1) }
      end

      context 'with defaults' do
        context 'when callable raises ArgumentError' do
          let(:callable) { lambda { Integer('abc') } }
          subject { Results.new(callable) }
          it { is_expected.to eq Results::Bad.new('invalid value for integer', callable) }
        end

        context 'when callable raises StandardError' do
          subject { lambda { Results.new(lambda { raise StandardError.new('abc') }) } }
          it { is_expected.to raise_error(StandardError, 'abc') }
        end
      end
    end

    context 'with block' do
      context 'when block does *not* raise' do
        subject { Results.new(1) { |v| v } }
        it { is_expected.to eq Results::Good.new(1) }
      end

      context 'with defaults' do
        context 'when block raises ArgumentError' do
          subject { Results.new('abc') { |v| Integer(v) } }
          it { is_expected.to eq Results::Bad.new('invalid value for integer', 'abc') }
        end

        context 'when block raises StandardError' do
          subject { lambda { Results.new('abc') { |v| raise StandardError.new(v) } } }
          it { is_expected.to raise_error(StandardError, 'abc') }
        end
      end
    end

  end

  ##
  # Construct directly by wrapping an existing Rescuer::Success or Rescuer::Failure
  ##
  describe '.from_rescuer' do

    context 'when success' do
      let(:success) { Rescuer::Success.new(1) }
      subject { Results.from_rescuer(success, 1) }
      it { is_expected.to eq Results::Good.new(1) }
    end

    context 'when failure' do
      let(:input) { 'abc' }
      let(:failure) { Rescuer::Failure.new(StandardError.new('failure message')) }
      subject { Results.from_rescuer(failure, input) }
      it { is_expected.to eq Results::Bad.new('failure message', 'abc') }
    end

  end

  ##
  # Transform exception messages via to configured lambdas
  ##
  describe '.transform_exception_message' do

    context 'with defaults' do
      context 'when argument error due to invalid integer' do
        subject { Results.transform_exception_message(begin; Integer('abc'); rescue => e; e; end) }
        it { is_expected.to eq 'invalid value for integer' }
      end

      context 'when argument error due to invalid float' do
        subject { Results.transform_exception_message(begin; Float('abc'); rescue => e; e; end) }
        it { is_expected.to eq 'invalid value for float' }
      end
    end

  end

  ##
  # Construct directly as Good
  ##
  describe Results::Good do
    let(:value) { 1 }
    let(:good) { Results::Good.new(value) }

    describe '#when' do
      context 'with true predicate' do
        subject { good.when('dummy') { |_| true } }
        it { is_expected.to be good }
      end

      context 'with false predicate and string error message, prepends "not"' do
        subject { good.when('true') { |_| false } }
        it { is_expected.to eq Results::Bad.new('not true', value) }
      end

      context 'with false predicate and callable error message' do
        subject { good.when(lambda { |v| "#{v} was not true" }) { |_| false } }
        it { is_expected.to eq Results::Bad.new('1 was not true', value) }
      end
    end

    describe '#when_not' do
      context 'with false predicate' do
        subject { good.when_not('dummy') { |_| false } }
        it { is_expected.to be good }
      end

      context 'with true predicate and string error message' do
        subject { good.when_not('evaluated as true') { |_| true } }
        it { is_expected.to eq Results::Bad.new('evaluated as true', value) }
      end

      context 'with failing predicate and callable error message' do
        subject { good.when_not(lambda { |v| "#{v} evaluated as true" }) { |_| true } }
        it { is_expected.to eq Results::Bad.new('1 evaluated as true', value) }
      end
    end

    describe '#validate' do
      context 'with return of good' do
        subject { good.validate { |_| good } }
        it { is_expected.to be good }
      end

      context 'with return of bad' do
        subject { good.validate { |v| Results::Bad.new("no good: #{v}", v) } }
        it { is_expected.to eq Results::Bad.new('no good: 1', value) }
      end
    end

  end

  ##
  # Construct directly as Bad
  ##
  describe Results::Bad do
    let(:msg) { 'epic fail' }
    let(:input) { 'abc' }
    let(:bad) { Results::Bad.new(msg, input) }

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
