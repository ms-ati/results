require 'rescuer'

module Results
  DEFAULT_EXCEPTIONS_TO_RESCUE_AS_BADS = [ArgumentError]
  DEFAULT_EXCEPTION_MESSAGE_TRANSFORMS = {
    ArgumentError => lambda { |m| m.gsub(/\Ainvalid (value|string) for [A-Z][a-zA-Z]+/) { |s| s.gsub('()', '').downcase } }
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

  Good = Struct.new(:value) do
    def when(msg_or_proc)
      validate { |v| yield(v) ? self : Bad.new(yield_or_call(msg_or_proc, value)) }
    end

    def when_not(msg_or_proc)
      validate { |v| !yield(v) ? self : Bad.new(yield_or_call(msg_or_proc, value) { |msg| 'not ' + msg }) }
    end

    def validate
      yield(value)
    end

    private

    def yield_or_call(msg_or_proc, *args)
      if !msg_or_proc.respond_to?(:call)
        block_given? ? yield(msg_or_proc) : msg_or_proc
      else
        msg_or_proc.call(*args)
      end
    end
  end

  Bad  = Struct.new(:error) do
    def when(msg_or_proc)
      self
    end

    def when_not(msg_or_proc)
      self
    end

    def validate
      self
    end
  end

end