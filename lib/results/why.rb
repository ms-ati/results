module Results
  module Why

    class Base
      def initialize
        raise(TypeError, 'cannot instantiate abstract class') if self.class == Results::Why::Base
      end
      private :initialize

      def +(that)
        raise(ArgumentError, 'not a valid Why') unless that.is_a? Why::Base
        self.promote(that) + that.promote(self)
      end

      def promote(that)
        case that
        when One   then self.to_many
        when Many  then self.to_many
        when Named then self.to_named
        end
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

      def to_named
        to_many.to_named
      end
    end

    # Explains a Bad caused by at least one Because
    class Many < Base
      def initialize(becauses)
        raise ArgumentError, 'not an Array of at least one Because' unless
          becauses.is_a?(Array) && !becauses.empty? && becauses.all? { |b| b.is_a? Because }
        @becauses = becauses
      end

      attr_reader :becauses

      def ==(that)
        that.is_a?(Many) && that.becauses == self.becauses
      end

      def to_many
        self
      end

      def to_named(name = :base)
        Named.new({ name => self.becauses })
      end

      def +(that)
        case that
        when Many then Many.new(self.becauses + that.becauses)
        else super
        end
      end
    end

    # Explains a Bad caused by at least one Because, each attributed to a named field
    class Named < Base
      def initialize(becauses_by_name)
        raise ArgumentError, 'not a Hash whose values are Arrays of at least one Because' unless
          becauses_by_name.is_a?(Hash) && !becauses_by_name.empty? &&
            becauses_by_name.values.all? { |a| !a.empty? && a.all? { |b| b.is_a? Because } }
        @becauses_by_name = becauses_by_name
      end

      attr_reader :becauses_by_name

      def ==(that)
        that.is_a?(Named) && that.becauses_by_name == self.becauses_by_name
      end

      def to_named
        self
      end

      def +(that)
        case that
        when Named
          Named.new(self.becauses_by_name.merge(that.becauses_by_name) { |_, self_val, that_val| self_val + that_val })
        else super
        end
      end

      def promote(that)
        self
      end
    end
  end

end