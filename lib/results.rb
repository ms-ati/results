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
      call_or_yield_or_return(input_or_proc) { |input| block_given? ? yield(input) : input }
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

  def when(*args)
    lambda { |v| Results.new(v).when(*args) }
  end
  module_function :when

  def when_not(*args)
    lambda { |v| Results.new(v).when_not(*args) }
  end
  module_function :when_not

  def predicate(method_name)
    Filter.new(method_name.to_s.gsub(/\?\Z/, '')) { |v| v.send(method_name) }
  end
  module_function :predicate

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
        predicate ? self : Bad.new(Results.call_or_yield_or_return(msg_or_proc, v) { |msg| 'not ' + msg }, v)
      end
    end

    def when_not(msg_or_proc_or_filter)
      validate do |v|
        predicate, msg_or_proc = extract_predicate_and_message(msg_or_proc_or_filter, v) { yield v }
        !predicate ? self : Bad.new(Results.call_or_yield_or_return(msg_or_proc, v), v)
      end
    end

    def validate
      yield(value)
    end

    private

    def extract_predicate_and_message(msg_or_proc_or_filter, v)
      if msg_or_proc_or_filter.is_a? Symbol
        p = Results.predicate(msg_or_proc_or_filter)
        [p.call(v), p.message]
      elsif msg_or_proc_or_filter.respond_to?(:call) && msg_or_proc_or_filter.respond_to?(:message)
        [msg_or_proc_or_filter.call(v), msg_or_proc_or_filter.message]
      else
        [yield, msg_or_proc_or_filter]
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

  # Helper which will call its argument, or yield it to a block, or simply return it,
  #   depending on what is possible with the given input
  def self.call_or_yield_or_return(proc_or_value, *args)
    if proc_or_value.respond_to?(:call)
      proc_or_value.call(*args)
    else
      block_given? ? yield(proc_or_value) : proc_or_value
    end
  end

end