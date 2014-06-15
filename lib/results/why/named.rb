module Results
  module Why

    # Explains a Bad caused by at least one Because, each attributed to a named field
    class Named < Base
      attr_reader :becauses_by_name

      def initialize(becauses_by_name)
        raise ArgumentError, 'not a Hash whose values are Arrays of at least one Because' unless
          becauses_by_name.is_a?(Hash) && !becauses_by_name.empty? &&
            becauses_by_name.values.all? { |v| v.is_a?(Array) && !v.empty? &&
              v.all? { |b| b.is_a? Because } }
        @becauses_by_name = becauses_by_name
      end

      def ==(other)
        other.is_a?(Named) && other.becauses_by_name == self.becauses_by_name
      end

      def to_named
        self
      end

      def +(other)
        case other
        when Named then Named.new(self.becauses_by_name.merge(other.becauses_by_name) { |_, a, b| a + b })
        else super
        end
      end
    end

  end
end
