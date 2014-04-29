require 'spec_helper'
require 'results'

describe Results do

  ##
  # Construct indirectly with a value or block which may raise an exception
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
  # Make a validation function from a filter using .when
  ##
  describe '.when' do

    shared_examples 'validation from a filter' do
      context 'when passes' do
        subject { Results.when(is_zero).call(0) }
        it { is_expected.to eq Results::Good.new(0) }
      end

      context 'when fails' do
        subject { Results.when(is_zero).call(1) }
        it { is_expected.to eq Results::Bad.new('not zero', 1) }
      end
    end

    context 'when instance of Results::Filter' do
      let(:is_zero) { Results::Filter.new('zero') { |n| n.zero? } }
      it_behaves_like 'validation from a filter'
    end

    context 'when a duck-type of #call and #message' do
      let(:is_zero) { lambda { |n| n.zero? }.tap { |l| l.define_singleton_method(:message) { 'zero' } } }
      it_behaves_like 'validation from a filter'
    end

  end

  ##
  # Make a validation function from a filter using .when_not
  ##
  describe '.when_not' do

    shared_examples 'validation from a filter' do
      context 'when passes' do
        subject { Results.when_not(is_zero).call(1) }
        it { is_expected.to eq Results::Good.new(1) }
      end

      context 'when fails' do
        subject { Results.when_not(is_zero).call(0) }
        it { is_expected.to eq Results::Bad.new('zero', 0) }
      end
    end

    context 'when instance of Results::Filter' do
      let(:is_zero) { Results::Filter.new('zero') { |n| n.zero? } }
      it_behaves_like 'validation from a filter'
    end

    context 'when a duck-type of #call and #message' do
      let(:is_zero) { lambda { |n| n.zero? }.tap { |l| l.define_singleton_method(:message) { 'zero' } } }
      it_behaves_like 'validation from a filter'
    end

  end

  ##
  # Make a filter from the symbol name of a predicate method using .predicate
  ##
  describe '.predicate' do
    context 'when symbol ends in ?, message strips the ?' do
      subject { Results.predicate(:zero?).message }
      it { is_expected.to eq 'zero' }
    end

    context 'when passes' do
      subject { Results.predicate(:zero?).call(0) }
      it { is_expected.to eq true }
    end

    context 'when fails' do
      subject { Results.predicate(:zero?).call(1) }
      it { is_expected.to eq false }
    end
  end

  ##
  # Transform exception message formatting via configured lambdas
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

      context 'with true predicate given by name' do
        subject { good.when(:nonzero?) }
        it { is_expected.to be good }
      end

      context 'with false predicate given by name' do
        subject { good.when(:zero?) }
        it { is_expected.to eq Results::Bad.new('not zero', value) }
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

      context 'with true predicate given by name' do
        subject { good.when_not(:nonzero?) }
        it { is_expected.to eq Results::Bad.new('nonzero', value) }
      end

      context 'with false predicate given by name' do
        subject { good.when_not(:zero?) }
        it { is_expected.to be good }
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

    describe '#and' do
      subject { good.and }
      it { is_expected.to be good }
    end

    describe '#when_all' do
      context 'with filters which are all true' do
        let(:filters_true) { Array.new(2) { |n| Results::Filter.new("f#{n}") { |_| true } } }

        context 'passed as array' do
          subject { good.when_all(filters_true) }
          it { is_expected.to be good }
        end

        context 'passed splatted' do
          subject { good.when_all(*filters_true) }
          it { is_expected.to be good }
        end
      end

      context 'with filters which are all false' do
        let(:filters_false) { Array.new(2) { |n| Results::Filter.new("f#{n}") { |_| false } } }
        let(:expected_bad) { Results::Bad.new(
          Results::Because.new('not f0', value),
          Results::Because.new('not f1', value)) }

        context 'passed as array' do
          subject { good.when_all(filters_false) }
          it { is_expected.to eq expected_bad }
        end

        context 'passed splatted' do
          subject { good.when_all(*filters_false) }
          it { is_expected.to eq expected_bad }
        end
      end
    end

    describe '#when_all_not' do
      context 'with filters which are all true' do
        let(:filters_true) { Array.new(2) { |n| Results::Filter.new("f#{n}") { |_| true } } }
        let(:expected_bad) { Results::Bad.new(
          Results::Because.new('f0', value),
          Results::Because.new('f1', value)) }

        context 'passed as array' do
          subject { good.when_all_not(filters_true) }
          it { is_expected.to eq expected_bad }
        end

        context 'passed splatted' do
          subject { good.when_all_not(*filters_true) }
          it { is_expected.to eq expected_bad }
        end
      end

      context 'with filters which are all false' do
        let(:filters_false) { Array.new(2) { |n| Results::Filter.new("f#{n}") { |_| false } } }

        context 'passed as array' do
          subject { good.when_all_not(filters_false) }
          it { is_expected.to be good }
        end

        context 'passed splatted' do
          subject { good.when_all_not(*filters_false) }
          it { is_expected.to be good }
        end
      end
    end

    describe '#zip' do
      context 'when other is good' do
        subject { good.zip(good) }
        it { is_expected.to eq Results::Good.new([value, value]) }
      end

      context 'when other is bad' do
        let(:bad) { Results::Bad.new('not ok', value) }
        subject { good.zip(bad) }
        it { is_expected.to be bad }
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
        subject { bad.validate { |_| Results::Good.new(2) } }
        it { is_expected.to be bad }
      end
    end

    describe '#and' do
      describe '#when' do
        context 'filter is true' do
          subject { bad.and.when('filter') { |_| true } }
          it { is_expected.to be bad }
        end

        context 'filter is false' do
          subject { bad.and.when('filter') { |_| false } }
          it { is_expected.to eq Results::Bad.new(Results::Because.new(msg, input),
                                                  Results::Because.new('not filter', input)) }
        end
      end

      describe '#when_not' do
        context 'filter is true' do
          subject { bad.and.when_not('filter') { |_| true } }
          it { is_expected.to eq Results::Bad.new(Results::Because.new(msg, input),
                                                  Results::Because.new('filter', input)) }
        end

        context 'filter is false' do
          subject { bad.and.when_not('filter') { |_| false } }
          it { is_expected.to be bad }
        end
      end
    end

    describe '#when_all' do
      context 'with filters which are all true' do
        let(:filters_true) { Array.new(2) { |n| Results::Filter.new("f#{n}") { |_| true } } }

        context 'passed as array' do
          subject { bad.when_all(filters_true) }
          it { is_expected.to be bad }
        end

        context 'passed splatted' do
          subject { bad.when_all(*filters_true) }
          it { is_expected.to be bad }
        end
      end

      context 'with filters which are all false' do
        let(:filters_false) { Array.new(2) { |n| Results::Filter.new("f#{n}") { |_| false } } }
        let(:expected_bad) { Results::Bad.new(
                               Results::Because.new(msg, input),
                               Results::Because.new('not f0', input),
                               Results::Because.new('not f1', input)) }

        context 'passed as array' do
          subject { bad.when_all(filters_false) }
          it { is_expected.to eq expected_bad }
        end

        context 'passed splatted' do
          subject { bad.when_all(*filters_false) }
          it { is_expected.to eq expected_bad }
        end
      end
    end

    describe '#when_all_not' do
      context 'with filters which are all true' do
        let(:filters_true) { Array.new(2) { |n| Results::Filter.new("f#{n}") { |_| true } } }
        let(:expected_bad) { Results::Bad.new(
                               Results::Because.new(msg, input),
                               Results::Because.new('f0', input),
                               Results::Because.new('f1', input)) }

        context 'passed as array' do
          subject { bad.when_all_not(filters_true) }
          it { is_expected.to eq expected_bad }
        end

        context 'passed splatted' do
          subject { bad.when_all_not(*filters_true) }
          it { is_expected.to eq expected_bad }
        end
      end

      context 'with filters which are all false' do
        let(:filters_false) { Array.new(2) { |n| Results::Filter.new("f#{n}") { |_| false } } }

        context 'passed as array' do
          subject { bad.when_all_not(filters_false) }
          it { is_expected.to be bad }
        end

        context 'passed splatted' do
          subject { bad.when_all_not(*filters_false) }
          it { is_expected.to be bad }
        end
      end
    end

    describe '#zip' do
      context 'when other is good' do
        subject { bad.zip(Results::Good.new(2)) }
        it { is_expected.to be bad }
      end

      context 'when other is bad' do
        subject { bad.zip(bad) }
        it { is_expected.to eq Results::Bad.new(bad.why + bad.why) }
      end
    end
  end

  ##
  # Helper class Filter for use with #when and #when_not
  ##
  describe Results::Filter do

    context 'with string message and block' do
      let(:filter_under_45) { Results::Filter.new('under 45') { |v| v < 45 } }

      context '#call when block returns false' do
        subject { filter_under_45.call(45) }
        it { is_expected.to be false }
      end

      context '#call when block returns true' do
        subject { filter_under_45.call(44) }
        it { is_expected.to be true }
      end

      context '#message' do
        subject { filter_under_45.message }
        it { is_expected.to eq 'under 45' }
      end
    end

    context 'with callable message' do
      let(:filter_callable_msg) { Results::Filter.new(lambda { |v| "value: #{v}" }) { |v| v } }
      subject { filter_callable_msg.message.call(1) }
      it { is_expected.to eq 'value: 1' }
    end

    context 'with nil message' do
      subject { lambda { Results::Filter.new(nil) { |v| v } } }
      it { is_expected.to raise_error(ArgumentError, 'invalid message') }
    end

    context 'with *no* block' do
      subject { lambda { Results::Filter.new('dummy') } }
      it { is_expected.to raise_error(ArgumentError, 'no block given') }
    end

  end

end
