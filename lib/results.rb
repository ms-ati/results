require 'rescuer'

module Results
  DEFAULT_EXCEPTIONS_TO_RESCUE_AS_BADS = [ArgumentError]
  DEFAULT_EXCEPTION_MESSAGE_TRANSFORMS = {
    ArgumentError => lambda do |m|
      r = /\Ainvalid (value|string) for ([A-Z][a-z]+)(\(\))?(: ".*")?\Z/
      m.gsub(r) { |_| "invalid value for #{$2}".downcase }
    end
  }

  def new(input)
    raise ArgumentError, 'no block given' unless block_given?

    exceptions_as_bad = DEFAULT_EXCEPTIONS_TO_RESCUE_AS_BADS
    exceptions_xforms = DEFAULT_EXCEPTION_MESSAGE_TRANSFORMS

    rescued = Rescuer.new(*exceptions_as_bad) { block_given? ? yield(input) : input }
    from_rescuer(rescued, input, exceptions_xforms)
  end
  module_function :new

  def from_rescuer(success_or_failure, input, exception_message_transforms = DEFAULT_EXCEPTION_MESSAGE_TRANSFORMS)
    success_or_failure.transform(
      lambda { |v| Good.new(v) },
      lambda { |e| Bad.new(transform_exception_message(e, exception_message_transforms), input) }
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
      validate { |v| yield(v) ? self : Bad.new(yield_or_call(msg_or_proc, v) { |msg| 'not ' + msg }, v) }
    end

    def when_not(msg_or_proc)
      validate { |v| !yield(v) ? self : Bad.new(yield_or_call(msg_or_proc, v), v) }
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

  Bad = Struct.new(:error, :input) do
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