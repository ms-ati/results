module Results
  def Why(arg)
    case arg
    when Because then Why::One.new(arg)
    when Array   then Why::Many.new(arg)
    when Hash    then Why::Named.new(arg)
    else raise TypeError, "can't convert #{arg.class} into Why"
    end
  end

  module Why

    class Base
      def +(other)
        raise(ArgumentError, 'not a valid Why') unless other.is_a? Why::Base
        self.promote(other) + other.promote(self)
      end

      protected

      def promote(other)
        case self
        when Named then self
        else case other
             when One   then self.to_many
             when Many  then self.to_many
             when Named then self.to_named
             end
        end
      end

      private

      def initialize
        raise(TypeError, 'cannot instantiate abstract class') if self.class == Results::Why::Base
      end
    end

    # Explains a Bad caused by exactly one Because
    class One < Base
      def initialize(because)
        raise ArgumentError, 'not a Because' unless because.is_a? Because
        @because = because
      end

      attr_reader :because

      def ==(other)
        other.is_a?(One) && other.because == self.because
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

      def ==(other)
        other.is_a?(Many) && other.becauses == self.becauses
      end

      def to_many
        self
      end

      def to_named(name = :base)
        Named.new({ name => self.becauses })
      end

      def +(other)
        case other
        when Many then Many.new(self.becauses + other.becauses)
        else super
        end
      end
    end

    # Explains a Bad caused by at least one Because, each attributed to a named field
    class Named < Base
      def initialize(becauses_by_name)
        raise ArgumentError, 'not a Hash whose values are Arrays of at least one Because' unless
          becauses_by_name.is_a?(Hash) && !becauses_by_name.empty? &&
            becauses_by_name.values.all? { |v| v.is_a?(Array) && !v.empty? &&
              v.all? { |b| b.is_a? Because } }
        @becauses_by_name = becauses_by_name
      end

      attr_reader :becauses_by_name

      def ==(other)
        other.is_a?(Named) && other.becauses_by_name == self.becauses_by_name
      end

      def to_named
        self
      end

      def +(other)
        case other
        when Named
          Named.new(self.becauses_by_name.merge(other.becauses_by_name) { |_, self_val, other_val| self_val + other_val })
        else super
        end
      end
    end
  end

end