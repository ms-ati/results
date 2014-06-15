module Results
  module Why
    # Follow AR convention, see http://guides.rubyonrails.org/active_record_validations.html#errors-base
    DEFAULT_NAME = :base

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

  end
end