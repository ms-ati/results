require 'rescuer'

module Results
  DEFAULT_EXCEPTIONS_TO_RESCUE_AS_BADS = [ArgumentError]
  DEFAULT_EXCEPTION_MESSAGE_TRANSFORMS = {
    ArgumentError => lambda do |m|
      r = /\Ainvalid (value|string) for ([A-Z][a-z]+)(\(\))?(: ".*")?\Z/
      m.gsub(r) { |_| "invalid value for #{$2}".downcase }
    end
  }

  def new(input_or_proc)
    exceptions_as_bad = DEFAULT_EXCEPTIONS_TO_RESCUE_AS_BADS
    exceptions_xforms = DEFAULT_EXCEPTION_MESSAGE_TRANSFORMS

    rescued = Rescuer.new(*exceptions_as_bad) do
      if input_or_proc.respond_to?(:call)
        input_or_proc.call
      else
        block_given? ? yield(input_or_proc) : input_or_proc
      end
    end

    from_rescuer(rescued, input_or_proc, exceptions_xforms)
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

  class Filter
    def initialize(msg_or_proc, &filter_block)
      raise ArgumentError, 'invalid message' if msg_or_proc.nil?
      raise ArgumentError, 'no block given' if filter_block.nil?
      @msg_or_proc, @filter_block = msg_or_proc, filter_block
    end

    def call(value)
      @filter_block.call(value)
    end

    def message
      @msg_or_proc
    end
  end

  Good = Struct.new(:value) do
    def when(msg_or_proc_or_filter)
      validate do |v|
        predicate, msg_or_proc = extract_predicate_and_message(msg_or_proc_or_filter, v) { yield v }
        predicate ? self : Bad.new(yield_or_call(msg_or_proc, v) { |msg| 'not ' + msg }, v)
      end
    end

    def when_not(msg_or_proc_or_filter)
      validate do |v|
        predicate, msg_or_proc = extract_predicate_and_message(msg_or_proc_or_filter, v) { yield v }
        !predicate ? self : Bad.new(yield_or_call(msg_or_proc, v), v)
      end
    end

    def validate
      yield(value)
    end

    private

    def extract_predicate_and_message(msg_or_proc_or_filter, v)
      if msg_or_proc_or_filter.respond_to?(:call) &&
        msg_or_proc_or_filter.respond_to?(:message)
        [msg_or_proc_or_filter.call(v), msg_or_proc_or_filter.message]
      else
        [yield, msg_or_proc_or_filter]
      end
    end

    def yield_or_call(msg_or_proc, *args)
      if msg_or_proc.respond_to?(:call)
        msg_or_proc.call(*args)
      else
        block_given? ? yield(msg_or_proc) : msg_or_proc
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