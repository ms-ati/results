module Results
  module Why

    class Base
      def initialize
        raise(TypeError, 'cannot instantiate abstract class') if self.class == Results::Why::Base
      end
      private :initialize

      def +(that)
        raise(ArgumentError, 'not a valid Why') unless that.is_a? Why::Base
        self.to_many + that.to_many
      end
    end

    # Explains a Bad caused by exactly one Because
    class One < Base
      def initialize(because)
        raise ArgumentError, 'not a Because' unless because.is_a? Because
        @because = because
      end

      attr_reader :because

      def ==(that)
        that.is_a?(One) && that.because == self.because
      end

      def to_many
        Many.new([self.because])
      end
    end

    # Explains a Bad caused by at least one Because
    class Many < Base
      def initialize(becauses)
        raise ArgumentError, 'not all Becauses' unless becauses.all? { |b| b.is_a? Because }
        @becauses = becauses
      end

      attr_reader :becauses

      def ==(that)
        that.is_a?(Many) && that.becauses == self.becauses
      end

      def to_many
        self
      end

      def +(that)
        case that
        when Many then Many.new(self.becauses + that.becauses)
        else super
        end
      end
    end

    # Explains a Bad caused by at least one Because, each associated with a named attribute
    class Attr < Base
      # IMPLEMENT ME
    end
  end

end