require 'spec_helper'
require 'results'

describe Results do

  ##
  # Construct indirectly by wrapping a block which may raise an exception
  ##
  describe '.new' do

    context 'with non-callable value and no block' do
      subject { Results.new(1) }
      it { is_expected.to eq Results::Good.new(1) }
    end

    shared_examples 'exception handler' do
      context 'when does *not* raise' do
        subject { when_does_not_raise }
        it { is_expected.to eq Results::Good.new(1) }
      end

      context 'when *does* raise' do
        let(:std_err) { StandardError.new('abc') }

        context 'with defaults' do
          context 'when raises ArgumentError' do
            subject { when_raises_arg_err }
            it { is_expected.to eq Results::Bad.new('invalid value for integer', input_raises_arg_err) }
          end

          context 'when raises StandardError' do
            subject { lambda { when_raises_std_err } }
            it { is_expected.to raise_error(StandardError, 'abc') }
          end
        end
      end
    end

    context 'with callable value' do
      let(:input_does_not_raise) { lambda { 1 } }
      let(:input_raises_arg_err) { lambda { Integer('abc') } }
      let(:input_raises_std_err) { lambda { raise std_err } }

      let(:when_does_not_raise) { Results.new(input_does_not_raise) }
      let(:when_raises_arg_err) { Results.new(input_raises_arg_err) }
      let(:when_raises_std_err) { Results.new(input_raises_std_err) }

      it_behaves_like 'exception handler'
    end

    context 'with block' do
      let(:input_does_not_raise) { 1 }
      let(:input_raises_arg_err) { 'abc' }
      let(:input_raises_std_err) { 'dummy' }

      let(:when_does_not_raise) { Results.new(input_does_not_raise) { |v| v } }
      let(:when_raises_arg_err) { Results.new(input_raises_arg_err) { |v| Integer(v) } }
      let(:when_raises_std_err) { Results.new(input_raises_std_err) { |_| raise std_err } }

      it_behaves_like 'exception handler'
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
