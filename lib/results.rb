require 'rescuer'

module Results
  DEFAULT_EXCEPTIONS_TO_RESCUE_AS_BADS = [ArgumentError]
  DEFAULT_EXCEPTION_MESSAGE_TRANSFORMS = {
    ArgumentError => lambda { |m| m.gsub(/\Ainvalid value for [A-Z][a-zA-Z]+\(\):/) { |s| s.gsub('()', '').downcase } }
  }

  def new
    raise ArgumentError, 'no block given' unless block_given?
    exceptions_as_bad = DEFAULT_EXCEPTIONS_TO_RESCUE_AS_BADS
    exceptions_xforms = DEFAULT_EXCEPTION_MESSAGE_TRANSFORMS
    from_rescuer(Rescuer.new(*exceptions_as_bad) { yield }, exceptions_xforms)
  end
  module_function :new

  def from_rescuer(success_or_failure, exception_message_transforms = DEFAULT_EXCEPTION_MESSAGE_TRANSFORMS)
    success_or_failure.transform(
      lambda { |v| Good.new(v) },
      lambda { |e| Bad.new(transform_exception_message(e, exception_message_transforms)) }
    ).get
  end
  module_function :from_rescuer

  def transform_exception_message(exception, exception_message_transforms = DEFAULT_EXCEPTION_MESSAGE_TRANSFORMS)
    _, f = exception_message_transforms.find { |klass, _| klass === exception }
    message = exception && exception.message
    f && f.call(message) || message
  end
  module_function :transform_exception_message

  Good = Struct.new(:value)
  Bad  = Struct.new(:error)
end