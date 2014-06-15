require 'results/why/base'
require 'results/why/one'
require 'results/why/many'
require 'results/why/named'

module Results

  # Wraps `arg` in a `Why` by calling the appropriate constructor.
  def Why(arg)
    case arg
    when Because then Why::One.new(arg)
    when Array   then Why::Many.new(arg)
    when Hash    then Why::Named.new(arg)
    else raise TypeError, "can't convert #{arg.class} into Why"
    end
  end

end