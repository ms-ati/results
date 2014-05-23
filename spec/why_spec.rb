require 'spec_helper'
require 'results'

include Results

describe Why do

  describe Why::Base do

    describe '.new' do
      subject { lambda { Why::Base.send(:new) } }
      it { is_expected.to raise_error(TypeError) }
    end

  end

  let(:a_because) { Because.new('reason', 'input') }
  let(:because_2) { Because.new('reason2', 'input2') }

  describe Why::One do
    let(:a_one) { Why::One.new(a_because) }
    let(:one_2) { Why::One.new(because_2) }

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
    let(:a_many) { Why::Many.new([a_because]) }
    let(:many_2) { Why::Many.new([because_2]) }

    describe '.new, #becauses' do
      context 'when given an array containing a Because' do
        subject { a_many.becauses }
        it { is_expected.to eq([a_because]) }
      end

      context 'when given anything other than an array containing Becauses' do
        subject { lambda { Why::Many.new(['foo']) } }
        it { is_expected.to raise_error(ArgumentError, 'not all Becauses') }
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

      context 'when given anything than than a Why' do
        subject { lambda { a_many + 'foo' } }
        it { is_expected.to raise_error(ArgumentError, 'not a valid Why') }
      end
    end
  end

end
