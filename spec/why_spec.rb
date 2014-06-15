require 'spec_helper'
require 'results'

include Results

describe Why do

  let(:a_because) { Because.new('reason', 'input') }
  let(:because_2) { Because.new('reason2', 'input2') }

  let(:a_one) { Why::One.new(a_because) }
  let(:one_2) { Why::One.new(because_2) }

  let(:a_many) { Why::Many.new([a_because]) }
  let(:many_2) { Why::Many.new([because_2]) }

  let(:a_named) { Why::Named.new({ 'a' => [a_because] }) }
  let(:named_2) { Why::Named.new({ 'a' => [because_2] }) }

  describe '(the function)' do

    context 'when given a single Because' do
      subject { Why(a_because) }
      it { is_expected.to eq(a_one) }
    end

    context 'when given an array containing a Because' do
      subject { Why([a_because]) }
      it { is_expected.to eq(a_many) }
    end

    context 'when given a hash containing a value of an array containing a Because' do
      subject { Why({ 'a' => [a_because] }) }
      it { is_expected.to eq(a_named) }
    end

    context 'when given anything other than a Because, an Array, or a Hash' do
      subject { lambda { Why('foo') } }
      it { is_expected.to raise_error(TypeError, "can't convert String into Why") }
    end

  end

  describe Why::Base do

    describe '.new' do
      subject { lambda { Why::Base.send(:new) } }
      it { is_expected.to raise_error(TypeError) }
    end

  end

  describe Why::One do

    describe '.new, #because' do
      context 'when given a Because' do
        subject { a_one.because }
        it { is_expected.to be(a_because) }
      end

      context 'when given anything other than a Because' do
        subject { lambda { Why::One.new('foo') } }
        it { is_expected.to raise_error(ArgumentError, 'not a Because') }
      end
    end

    describe '#==' do
      it { expect(a_one).to eq(Why::One.new(Because.new('reason', 'input'))) }
    end

    describe '#to_many' do
      subject { a_one.to_many }
      it { is_expected.to eq(Why::Many.new([a_because])) }
    end

    describe '#+' do
      context 'when given a One' do
        subject { a_one + one_2 }
        it { is_expected.to eq(Why::Many.new([a_because, because_2])) }
      end

      context 'when given a Many' do
        let(:a_many) { Why::Many.new([because_2]) }
        subject { a_one + a_many }
        it { is_expected.to eq(Why::Many.new([a_because, because_2])) }
      end

      context 'when given anything than than a Why' do
        subject { lambda { a_one + 'foo' } }
        it { is_expected.to raise_error(ArgumentError, 'not a valid Why') }
      end
    end
  end

  describe Why::Many do

    describe '.new, #becauses' do
      context 'when given an array containing a Because' do
        subject { a_many.becauses }
        it { is_expected.to eq([a_because]) }
      end

      let(:arg_err_msg) { 'not an Array of at least one Because' }

      context 'when given an array containing something other than a Because' do
        subject { lambda { Why::Many.new(['foo']) } }
        it { is_expected.to raise_error(ArgumentError, arg_err_msg) }
      end

      context 'when given an empty array' do
        subject { lambda { Why::Many.new([]) } }
        it { is_expected.to raise_error(ArgumentError, arg_err_msg) }
      end

      context 'when given anything other than an array' do
        subject { lambda { Why::Many.new('foo') } }
        it { is_expected.to raise_error(ArgumentError, arg_err_msg) }
      end
    end

    describe '#==' do
      it { expect(a_many).to eq(Why::Many.new([Because.new('reason', 'input')])) }
    end

    describe '#to_many' do
      subject { a_many.to_many }
      it { is_expected.to be(a_many) }
    end

    describe '#+' do
      context 'when given a One' do
        let(:a_one) { Why::One.new(because_2) }
        subject { a_many + a_one }
        it { is_expected.to eq(Why::Many.new([a_because, because_2])) }
      end

      context 'when given a Many' do
        subject { a_many + many_2 }
        it { is_expected.to eq(Why::Many.new([a_because, because_2])) }
      end

      context 'when given anything than than a Why' do
        subject { lambda { a_many + 'foo' } }
        it { is_expected.to raise_error(ArgumentError, 'not a valid Why') }
      end
    end
  end

  describe Why::Named do

    describe '.new, #becauses_by_name' do
      context 'when given a hash containing a value of an array containing a Because' do
        subject { a_named.becauses_by_name }
        it { is_expected.to eq({ 'a' => [a_because] }) }
      end

      let(:arg_err_msg) { 'not a Hash whose values are Arrays of at least one Because' }

      context 'when given a hash containing a value of an array containing something other than a Because' do
        subject { lambda { Why::Named.new({ 'a' => ['foo'] }) } }
        it { is_expected.to raise_error(ArgumentError, arg_err_msg) }
      end

      context 'when given a hash containing a value of an empty array' do
        subject { lambda { Why::Named.new({ 'a' => [] }) } }
        it { is_expected.to raise_error(ArgumentError, arg_err_msg) }
      end

      context 'when given a hash containing a value of anything other than an array' do
        subject { lambda { Why::Named.new({ 'a' => 42 }) } }
        it { is_expected.to raise_error(ArgumentError, arg_err_msg) }
      end

      context 'when given an empty hash' do
        subject { lambda { Why::Named.new({}) } }
        it { is_expected.to raise_error(ArgumentError, arg_err_msg) }
      end

      context 'when given anything other than a hash' do
        subject { lambda { Why::Named.new('foo') } }
        it { is_expected.to raise_error(ArgumentError, arg_err_msg) }
      end
    end

    describe '#==' do
      it { expect(a_named).to eq(Why::Named.new({ 'a' => [Because.new('reason', 'input')] })) }
    end

    describe '#to_named' do
      subject { a_named.to_named }
      it { is_expected.to be(a_named) }
    end

    describe '#+' do
      context 'when given a One' do
        let(:a_one) { Why::One.new(because_2) }
        subject { a_named + a_one }
        it { is_expected.to eq(Why::Named.new({ 'a'   => [a_because],
                                                :base => [because_2] })) }
      end

      context 'when given a Many' do
        let(:a_many) { Why::Many.new([because_2]) }
        subject { a_named + a_many }
        it { is_expected.to eq(Why::Named.new({ 'a'   => [a_because],
                                                :base => [because_2] })) }
      end

      context 'when given a Named' do
        subject { a_named + named_2 }
        it { is_expected.to eq(Why::Named.new({ 'a'   => [a_because, because_2] })) }
      end

      context 'when given anything than than a Why' do
        subject { lambda { a_named + 'foo' } }
        it { is_expected.to raise_error(ArgumentError, 'not a valid Why') }
      end
    end
  end

end
