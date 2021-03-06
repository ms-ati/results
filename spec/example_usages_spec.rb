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
    _ = parseAge(str)
    _ = _.when    ('under 45') { |v| v < 45 }
    _ = _.when_not('under 21') { |v| v < 21 }
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
      subject {
        parseAge('16')
          .when(under_45)
          .when_not(under_21).inspect
      }
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

      let(:filters) { [:integer?, :zero?, Results::Filter.new('greater than 2') { |n| n > 2 }] }

      context 'Results.new(1.23).when_all(filters)' do
        subject { Results.new(1.23).when_all(filters).inspect }
        it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="not integer", input=1.23>, ' +
                                                          '#<struct Results::Because error="not zero", input=1.23>, ' +
                                                          '#<struct Results::Because error="not greater than 2", input=1.23>]>' }
      end

    end

    describe 'Combine results of multiple inputs' do
      let(:good) { Results::Good.new(1) }
      let(:bad1) { Results::Bad.new('not nonzero', 0) }
      let(:bad2) { Results::Bad.new('not integer', 1.23) }

      context 'good.zip(good)' do
        subject { good.zip(good).inspect }
        it { is_expected.to eq '#<struct Results::Good value=[1, 1]>' }
      end

      context 'good.zip(bad1).zip(bad2)' do
        subject { good.zip(bad1).zip(bad2).inspect }
        it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="not nonzero", input=0>, ' +
                                                          '#<struct Results::Because error="not integer", input=1.23>]>' }
      end

      let(:all_good_results) { [good, good, good] }
      let(:some_bad_results) { [bad1, good, bad2] }

      context 'Results.combine(all_good_results)' do
        subject { Results.combine(all_good_results).inspect }
        it { is_expected.to eq '#<struct Results::Good value=[1, 1, 1]>' }
      end

      context 'Results.combine(some_bad_results)' do
        subject { Results.combine(some_bad_results).inspect }
        it { is_expected.to eq '#<struct Results::Bad why=[#<struct Results::Because error="not nonzero", input=0>, ' +
                                                          '#<struct Results::Because error="not integer", input=1.23>]>' }
      end

    end

  end

  describe 'TODO: Name This Usage Example' do
    # A deceptively simple function:
    #   Given a series of colors with weights, combine them.
    #
    # Colors may be specified via the full name, the snake-case id, 3-digit hex
    # rgb, 6-digit hex rgb, or base-10 rgb triplet. Source data comes from
    # Wikipedia,via:
    #   http://en.wikipedia.org/wiki/List_of_colors
    #   https://github.com/codebrainz/color-names/blob/master/output/colors.csv
    #
    # So where may errors occur?
    #   1. Parsing of input, which must be a hash
    #      a. Value for 'summary' must be a hash
    #         1. Value for 'num_rows' must be an integer
    #         2. Value for 'timestamp' must be a string
    #      b. Value for 'rows' must be an array
    #         1. Each row must be a hash
    #            a. Value for 'color' must be a string
    #            b. Optional value for 'weight', if present, must be a number
    #   2. Semantic meaning of parsed input
    #      a. Value for 'num_rows' must be non-negative and match actual number of rows
    #      b. Value for 'timestamp' must be a valid ISO timestamp
    #      c. Value for 'color' must be a valid color in one of the allowed formats
    #      d. Value for 'weight' must be non-negative, defaulting to 1 if absent
    #   3. Combination
    #      a. Values combine ok
    #      b. Find nearest named color
    #   4. Presentation of result
    #      a. Return name of combined color
    #
    # Let's build this out of individually testable, composed functions.

    # Expected input after JSON load
    let(:input_when_good) { {
      'summary' => {
        'num_rows'  => 2,                          # matches number of rows below
        'timestamp' => '2014-05-20T16:39:00Z-0400' # JSON loads time as un-parsed ISO 8601 string
      },
      'rows' => [
        { 'color' => 'red'                    }, # ok to have no weight
        { 'color' => 'green', 'weight' => 1.0 }  # float weight is ok
      ]
    } }

    # Expected good output, matching combined result to named color
    let(:expect_out_good) { Results::Good.new('Yellow') }

    # Bad inputs and outputs
    let(:input_when_bad_not_hash) { [] }
    let(:expect_out_bad_not_hash) { Results::Bad.new('not a hash', []) }

    let(:input_when_bad_parsing_summary_and_rows) { {
      'summary' => [],
      'rows'    => {},
      'foo'     => 'bar'
    } }
    let(:expect_out_bad_parsing_summary_and_rows) {
      Results::Bad.new(
        {
          'summary' => [Results::Because.new('not a hash', [])],
          'rows'    => [Results::Because.new('not an array', {})],
          :base     => [Results::Because.new('unknown attribute', 'foo')]
        }
      )
    }

    let(:input_when_one_bad_row) { input_when_good.merge(
      {
        'rows' => [
          input_when_good['rows'][0],  # copied a good row, no problems
          ['weight', 1.0]              # not a hash
        ]
      })
    }
    let(:expect_out_one_bad_row) {
      Results::Bad.new(
        {
          'rows' => {
            1 => [Results::Because.new('not a hash', ['weight', 1.0])]
          }
        }
      )
    }

    let(:input_when_bad_parsing_leaf_nodes) { {
      'summary' => {
        'num_rows'  => '2',                                    # not an integer
        'timestamp' => 123456.7                                # not a string
      },
      'rows' => [
        { 'weight' => 1 },                                     # missing color
        { 'color' => :green, 'weight' => nil, 'foo' => 'bar' } # not a string, not a number, unknown 'foo'
      ]
    } }
    let(:expect_out_bad_parsing_leaf_nodes) {
      Results::Bad.new(
        {
          'summary' => {
            'num_rows'  => [Results::Because.new('not an integer', '2')],
            'timestamp' => [Results::Because.new('not a string', 123456.7)]
          },
          'rows' => {
            0 => {
              'color'   => [Results::Because.new('missing key', nil)]
            },
            1 => {
              'color'   => [Results::Because.new('not a string', :green)],
              'weight'  => [Results::Because.new('not a number', nil)],
              :base     => [Results::Because.new('unknown key', 'foo')],
            }
          }
        }
      )
    }

    let(:table) { {
      'red'    => { 'name' => 'Red',    'hex' => '#f00', 'rgb' => [255,   0, 0] },
      'green'  => { 'name' => 'Green',  'hex' => '#0f0', 'rgb' => [0,   255, 0] },
      'yellow' => { 'name' => 'Yellow', 'hex' => '#ff0', 'rgb' => [255, 255, 0] },
    } }

    def combine_colors(input)
      is_a_hash = Results::Filter.new('a hash') { |v| v.is_a? Hash }
      _ = Results.new(input)

      # following lines are logically together: #validate_hash or something?
      _ = _.when(is_a_hash) # it is a hash
      _ = _.validate do |hsh|
        known_keys = %w(summary rows)
        missing_key = Results::Filter.new(lambda { |_| 'missing key' }) { |k| hsh.key? k }
        unknown_key = Results::Filter.new(lambda { |_| 'unknown key' }) { |k| known_keys.include? k }

        Results.combine(known_keys.map { |k| Results.new(k).when(missing_key) } +
                          hsh.keys.map { |k| Results.new(k).when(unknown_key) })
      end
    end

    it 'returns good result on happy path' do
      pending
      expect(combine_colors(input_when_good)).to eq(expect_out_good)
    end

    it 'returns a single top-level bad result when input not a hash' do
      expect(combine_colors(input_when_bad_not_hash)).to eq(expect_out_bad_not_hash)
    end

    it 'returns multiple parsing failures at first-level values' do
      #pending
      expect(combine_colors(input_when_bad_parsing_summary_and_rows)).to eq(expect_out_bad_parsing_summary_and_rows)
    end

    it 'returns a parsing failure with index when a row is not a hash' do
      pending
      expect(combine_colors(input_when_one_bad_row)).to eq(expect_out_one_bad_row)
    end

    it 'returns multiple parsing failures at leaf-node values' do
      pending
      expect(combine_colors(input_when_bad_parsing_leaf_nodes)).to eq(expect_out_bad_parsing_leaf_nodes)
    end

    # NOTE: how about Why::One, ::Many, ::Attr
    #   One holds a Because
    #   Many holds a non-empty array of Because
    #   Attr holds a hash with values which are array of Because or hashes

  end

end