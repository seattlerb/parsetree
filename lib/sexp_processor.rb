
$TESTING = false unless defined? $TESTING

class Object

  ##
  # deep_clone is the usual Marshalling hack to make a deep copy.
  # It is rather slow, so use it sparingly. Helps with debugging
  # SexpProcessors since you usually shift off sexps.

  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

##
# Sexps are the basic storage mechanism of SexpProcessor.  Sexps have
# a +type+ (to be renamed +node_type+) which is the first element of
# the Sexp. The type is used by SexpProcessor to determine whom to
# dispatch the Sexp to for processing.

class Sexp < Array # ZenTest FULL

  @@array_types = [ :array, :args, ]

  ##
  # Named positional parameters.
  # Use with +SexpProcessor.require_empty=false+.
  attr_accessor :accessors

  ##
  # Create a new Sexp containing +args+.

  def initialize(*args)
    @accessors = []
    super(args)
  end

  ##
  # Returns true if the node_type is +array+ or +args+.
  #
  # REFACTOR: to TypedSexp - we only care when we have units.

  def array_type?
    type = self.first
    @@array_types.include? type
  end

  ##
  # Enumeratates the sexp yielding to +b+ when the node_type == +t+.

  def each_of_type(t, &b)
    each do | elem |
      if Sexp === elem then
        elem.each_of_type(t, &b)
        b.call(elem) if elem.first == t
      end
    end
  end

  ##
  # Replaces all elements whose node_type is +from+ with +to+. Used
  # only for the most trivial of rewrites.

  def find_and_replace_all(from, to)
    each_with_index do | elem, index |
      if Sexp === elem then
        elem.find_and_replace_all(from, to)
      else
        self[index] = to if elem == from
      end
    end
  end

  ##
  # Fancy-Schmancy method used to implement named positional accessors
  # via +accessors+.
  #
  # Example:
  #
  #   class MyProcessor < SexpProcessor
  #     def initialize
  #       super
  #       self.require_empty = false
  #       self.sexp_accessors = {
  #         :call => [:lhs, :name, :rhs]
  #       }
  #       ...
  #     end
  #   
  #     def process_call(exp)
  #       lhs = exp.lhs
  #       name = exp.name
  #       rhs = exp.rhs
  #       ...
  #     end
  #   end

  def method_missing(meth, *a, &b)
    super unless @accessors.include? meth

    index = @accessors.index(meth) + 1 # skip type
    return self.at(index)
  end

  ##
  # Returns the Sexp without the node_type.

  def sexp_body
    self[1..-1]
  end

  ##
  # Returnes the bare bones structure of the sexp.
  # s(:a, :b, s(:c, :d), :e) => s(:a, s(:c))

  def structure
    result = self.class.new
    if Array === self.first then
      result = self.first.structure
    else
      result << self.shift
      self.grep(Array).each do |subexp|
        result << subexp.structure
      end
    end
    result
  end

  def ==(obj) # :nodoc:
    case obj
    when Sexp
      super
    else
      false
    end
  end

  def to_a # :nodoc:
    self.map { |o| Sexp === o ? o.to_a : o }
  end

  def inspect # :nodoc:
    sexp_str = self.map {|x|x.inspect}.join(', ')
    return "s(#{sexp_str})"
  end

  def pretty_print(q) # :nodoc:
    q.group(1, 's(', ')') do
      q.seplist(self) {|v| q.pp v }
    end
  end

  def to_s # :nodoc:
    inspect
  end

  ##
  # If run with debug, Sexp will raise if you shift on an empty
  # Sexp. Helps with debugging.

  def shift
    raise "I'm empty" if self.empty?
    super
  end if $DEBUG or $TESTING

end

##
# This is just a stupid shortcut to make indentation much cleaner.

def s(*args)
  Sexp.new(*args)
end

##
# Raised by SexpProcessor if it sees a node type listed in its
# unsupported list.

class UnsupportedNodeError < SyntaxError; end

##
# Raised by SexpProcessor if a processor did not process every node in
# a sexp and @require_empty is true.

class NotEmptyError < SyntaxError; end

##
# SexpProcessor provides a uniform interface to process Sexps.
#
# In order to create your own SexpProcessor subclass you'll need
# to call super in the initialize method, then set any of the
# Sexp flags you want to be different from the defaults.
#
# SexpProcessor uses a Sexp's type to determine which process method
# to call in the subclass.  For Sexp <code>s(:lit, 1)</code>
# SexpProcessor will call #process_lit, if it is defined.
#
# You can also specify a default method to call for any Sexp types
# without a process_<type> method or use the default processor provided to
# skip over them.
#
# Here is a simple example:
#
#   class MyProcessor < SexpProcessor
#     def initialize
#       super
#       self.strict = false
#     end
#   
#     def process_lit(exp)
#       val = exp.shift
#       return val
#     end
#   end

class SexpProcessor
  
  ##
  # A default method to call if a process_<type> method is not found
  # for the Sexp type.

  attr_accessor :default_method

  ##
  # Emit a warning when the method in #default_method is called.

  attr_accessor :warn_on_default

  ##
  # Automatically shifts off the Sexp type before handing the
  # Sexp to process_<type>

  attr_accessor :auto_shift_type

  ##
  # An array that specifies node types that are unsupported by this
  # processor. SexpProcesor will raise UnsupportedNodeError if you try
  # to process one of those node types.

  attr_accessor :unsupported

  ##
  # Raise an exception if no process_<type> method is found for a Sexp.

  attr_accessor :strict

  ##
  # A Hash of Sexp types and Regexp.
  #
  # Print a debug message if the Sexp type matches the Hash key
  # and the Sexp's #inspect output matches the Regexp.

  attr_accessor :debug

  ##
  # Expected result class

  attr_accessor :expected

  ##
  # Raise an exception if the Sexp is not empty after processing

  attr_accessor :require_empty

  ##
  # Adds accessor methods to the Sexp

  attr_accessor :sexp_accessors

  ##
  # Creates a new SexpProcessor.  Use super to invoke this
  # initializer from SexpProcessor subclasses, then use the
  # attributes above to customize the functionality of the
  # SexpProcessor

  def initialize
    @collection = []
    @default_method = nil
    @warn_on_default = true
    @auto_shift_type = false
    @strict = false
    @unsupported = []
    @debug = {}
    @expected = Sexp
    @require_empty = true
    @sexp_accessors = {}

    # we do this on an instance basis so we can subclass it for
    # different processors.
    @processors = {}
    @rewriters  = {}

    public_methods.each do |name|
      case name
      when /^process_(.*)/ then
        @processors[$1.intern] = name.intern
      when /^rewrite_(.*)/ then
        @rewriters[$1.intern]  = name.intern
      end
    end
  end

  ##
  # Default Sexp processor.  Invokes process_<type> methods matching
  # the Sexp type given.  Performs additional checks as specified by
  # the initializer.

  def process(exp)
    return nil if exp.nil?

    exp_orig = exp.deep_clone if $DEBUG
    result = self.expected.new

    type = exp.first

    if @debug.include? type then
      str = exp.inspect
      puts "// DEBUG: #{str}" if str =~ @debug[type]
    end

    if Sexp === exp then
      if @sexp_accessors.include? type then
        exp.accessors = @sexp_accessors[type]
      else
        exp.accessors = [] # clean out accessor list in case it changed
      end
    end
    
    raise UnsupportedNodeError, "'#{type}' is not a supported node type." if @unsupported.include? type

    # do a pass through the rewriter first, if any, reassign back to exp
    meth = @rewriters[type]
    if meth then
      new_exp = self.send(meth, exp)
      # REFACTOR: duplicated from below
      if @require_empty and not exp.empty? then
        msg = "exp not empty after #{self.class}.#{meth} on #{exp.inspect}"
        if $DEBUG then
          msg += " from #{exp_orig.inspect}" 
        end
        raise NotEmptyError, msg
      end
      exp = new_exp
    end

    # now do a pass with the real processor (or generic
    meth = @processors[type] || @default_method
    if meth then

      if @warn_on_default and meth == @default_method then
        $stderr.puts "WARNING: Using default method #{meth} for #{type}"
      end

      exp.shift if @auto_shift_type and meth != @default_method

      result = self.send(meth, exp)
      raise TypeError, "Result must be a #{@expected}, was #{result.class}:#{result.inspect}" unless @expected === result

      if @require_empty and not exp.empty? then
        msg = "exp not empty after #{self.class}.#{meth} on #{exp.inspect}"
        if $DEBUG then
          msg += " from #{exp_orig.inspect}" 
        end
        raise NotEmptyError, msg
      end
    else
      unless @strict then
        until exp.empty? do
          sub_exp = exp.shift
          sub_result = nil
          if Array === sub_exp then
            sub_result = process(sub_exp)
            raise "Result is a bad type" unless Array === sub_exp
            raise "Result does not have a type in front: #{sub_exp.inspect}" unless Symbol === sub_exp.first unless sub_exp.empty?
          else
            sub_result = sub_exp
          end
          result << sub_result
        end

        # NOTE: this is costly, but we are in the generic processor
        # so we shouldn't hit it too much with RubyToC stuff at least.
        #if Sexp === exp and not exp.sexp_type.nil? then
        begin
          result.sexp_type = exp.sexp_type
        rescue Exception
          # nothing to do, on purpose
        end
      else
        raise SyntaxError, "Bug! Unknown type #{type.inspect} to #{self.class}"
      end
    end
    result
  end

  def generate # :nodoc:
    raise "not implemented yet"
  end

  ##
  # Raises unless the Sexp type for +list+ matches +typ+

  def assert_type(list, typ)
    raise TypeError, "Expected type #{typ.inspect} in #{list.inspect}" if
      list.first != typ
  end

  ##
  # A fairly generic processor for a dummy node. Dummy nodes are used
  # when your processor is doing a complicated rewrite that replaces
  # the current sexp with multiple sexps.
  #
  # Bogus Example:
  #
  # def process_something(exp)
  #   return s(:dummy, process(exp), s(:extra, 42))

  def process_dummy(exp)
    result = @expected.new(:dummy)
    until exp.empty? do
      result << self.process(exp.shift)
    end
    result
  end
end

