require 'results/why/base'
require 'results/why/one'
require 'results/why/many'
require 'results/why/named'

module Results
  module_function

  # Wraps `becauses` into the appropriate `Why` depending on its type: `One`, `Many`, or `Named`.
  # @param [Why, Because, Array<Because>, Hash<Object, Because>] becauses  one or more `Because`'s to wrap in a `Why`
  # @return [Why::Base]  wrapped explanation(s) as a {Why::One One}, a {Why::Many Many}, or a {Why::Named Named}
  def Why(becauses)
    case becauses
    when Why::Base then becauses
    when Because   then Why::One.new(becauses)
    when Array     then Why::Many.new(becauses)
    when Hash      then Why::Named.new(becauses)
    else raise TypeError, "can't convert #{becauses.class} into Why"
    end
  end

end