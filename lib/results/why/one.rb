module Results
  module Why

    # Explains a Bad caused by exactly one Because
    class One < Base
      attr_reader :because

      def initialize(because)
        raise ArgumentError, 'not a Because' unless because.is_a? Because
        @because = because
      end

      def input
        because.input
      end

      def ==(other)
        other.is_a?(One) && other.because == self.because
      end

      def to_many
        Many.new([self.because])
      end

      def to_named(name = DEFAULT_NAME)
        to_many.to_named(name)
      end
    end

  end
end
