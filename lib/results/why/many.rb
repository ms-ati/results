module Results
  module Why

    # Explains a Bad caused by at least one Because
    class Many < Base
      attr_reader :becauses

      def initialize(becauses)
        raise ArgumentError, 'not an Array of at least one Because' unless
          becauses.is_a?(Array) && !becauses.empty? && becauses.all? { |b| b.is_a? Because }
        @becauses = becauses
      end

      def input
        becauses.last.input
      end

      def ==(other)
        other.is_a?(Many) && other.becauses == self.becauses
      end

      def to_many
        self
      end

      def to_named(name = DEFAULT_NAME)
        Named.new({ name => self.becauses })
      end

      def +(other)
        case other
        when Many then Many.new(self.becauses + other.becauses)
        else super
        end
      end
    end

  end
end
