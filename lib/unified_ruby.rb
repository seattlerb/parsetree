require 'sexp_processor'

$TESTING ||= false

module UnifiedRuby
  def process exp
    exp = Sexp.from_array exp unless Sexp === exp or exp.nil?
    super
  end

  def rewrite_attrasgn(exp)
    last = exp.last

    if Sexp === last then
      last[0] = :arglist if last[0] == :array
    else
      exp << s(:arglist)
    end

    exp
  end

  def rewrite_bmethod(exp)
    _, args, body = exp

    args ||= s(:array)
    body ||= s(:block)

    args = s(:args, args) unless args[0] == :array

    args = args[1] if args[1] && args[1][0] == :masgn # TODO: clean up
    args = args[1] if args[1] && args[1][0] == :array
    args[0] = :args

    # this is ugly because rewriters are depth first.
    # TODO: maybe we could come up with some way to do both forms of rewriting.
    args.map! { |s|
      if Sexp === s
        case s[0]
        when :lasgn then
          s[1]
        when :splat then
          :"*#{s[1][1]}"
        else
          raise "huh?: #{s.inspect}"
        end
      else
        s
      end
    }

    body = s(:block, body) unless body[0] == :block
    body.insert 1, args

    s(:scope, body)
  end

  def rewrite_argscat exp
    _, ary, val = exp
    ary = s(:array, ary) unless ary.first == :array
    ary << s(:splat, val)
  end

  def rewrite_argspush exp
    exp[0] = :arglist
    exp
  end

  def rewrite_block_pass exp
    if exp.size == 3 then
      _, block, recv = exp
      case recv.first
      when :super then
        recv << s(:block_pass, block)
        exp = recv
      when :call then
        recv.last << s(:block_pass, block)
        exp = recv
      else
        raise "huh?: #{recv.inspect}"
      end
    end

    exp
  end

  def rewrite_call(exp)
    args = exp.last
    case args
    when nil
      exp.pop
    when Array
      case args.first
      when :array, :arglist then
        args[0] = :arglist
      when :argscat, :splat then
        exp[-1] = s(:arglist, args)
      else
        raise "unknown type in call #{args.first.inspect} in #{exp.inspect}"
      end
      return exp
    end

    exp << s(:arglist)

    exp
  end

  def rewrite_dasgn(exp)
    exp[0] = :lasgn
    exp
  end

  alias :rewrite_dasgn_curr :rewrite_dasgn

  ##
  # :defn is one of the most complex of all the ASTs in ruby. We do
  # one of 3 different translations:
  #
  # 1) From:
  #
  #   s(:defn, :name, s(:scope, s(:block, s(:args, ...), ...)))
  #   s(:defn, :name, s(:bmethod, s(:masgn, s(:dasgn_curr, :args)), s(:block, ...)))
  #   s(:defn, :name, s(:fbody, s(:bmethod, s(:masgn, s(:dasgn_curr, :splat)), s(:block, ...))))
  #
  # to:
  #
  #   s(:defn, :name, s(:args, ...), s(:scope, s:(block, ...)))
  #
  # 2) From:
  #
  #   s(:defn, :writer=, s(:attrset, :@name))
  #
  # to:
  #
  #   s(:defn, :writer=, s(:args), s(:attrset, :@name))
  #
  # 3) From:
  #
  #   s(:defn, :reader, s(:ivar, :@name))
  #
  # to:
  #
  #   s(:defn, :reader, s(:args), s(:ivar, :@name))
  #

  def rewrite_defn(exp)
    weirdo = exp.ivar || exp.attrset

    fbody = exp.fbody(true)
    exp.push(fbody.scope) if fbody

    args = exp.scope.block.args(true) unless weirdo
    exp.insert 2, args if args

    # move block_arg up and in
    block_arg = exp.scope.block.block_arg(true) rescue nil
    if block_arg
      block = args.block(true)
      args << :"&#{block_arg.last}"
      args << block if block
    end

    # patch up attr_accessor methods
    if weirdo then
      case
      when exp.ivar then
        exp.insert 2, s(:args)
      when exp.attrset then
        exp.insert 2, s(:args, :arg)
      else
        raise "unknown wierdo: #{wierdo.inpsect}"
      end
    end

    exp
  end

  def rewrite_defs(exp)
    receiver = exp.delete_at 1

    # TODO: I think this would be better as rewrite_scope, but that breaks others
    exp = s(exp.shift, exp.shift,
            s(:scope,
              s(:block, exp.scope.args))) if exp.scope.args

    result = rewrite_defn(exp)
    result.insert 1, receiver

    result
  end

  def rewrite_dmethod(exp)
    exp.shift # type
    exp.shift # dmethod name
    exp.shift # scope / block / body
  end

  def rewrite_dvar(exp)
    exp[0] = :lvar
    exp
  end

  def rewrite_fcall(exp)
    exp[0] = :call
    exp.insert 1, nil
    exp.push nil if exp.size <= 3

    rewrite_call(exp)
  end

  def rewrite_masgn(exp)
    raise "wtf: #{exp}" unless exp.size == 4

    t, lhs, lhs_splat, rhs = exp

    lhs ||= s(:array)

    if lhs_splat then
      lhs_splat = s(:splat, lhs_splat) unless lhs_splat[0] == :splat
      lhs << lhs_splat
    end

    s(t, lhs, rhs).compact
  end

  def rewrite_op_asgn1(exp)
    exp[2][0] = :arglist # if exp[2][0] == :array
    exp
  end

  def rewrite_rescue(exp)
    # SKETCHY HACK return exp if exp.size > 4
    ignored = exp.shift
    body    = exp.shift unless exp.first.first == :resbody
    resbody = exp.shift
    els     = exp.shift unless exp.first.first == :resbody unless exp.empty?
    rest    = exp.empty? ? nil : exp # graceful re-rewriting (see rewrite_begin)

    resbodies = []

    unless rest then
      while resbody do
        resbodies << resbody
        resbody = resbody.resbody(true)
      end

      resbodies.each do |resbody|
        if resbody[2] && resbody[2][0] == :block && resbody[2].size == 2 then
          resbody[2] = resbody[2][-1]
        end
      end
    else
      resbodies = [resbody] + rest
    end

    resbodies << els if els

    s(:rescue, body, *resbodies).compact
  end

  def rewrite_resbody(exp)
    exp[1] ||= s(:array)        # no args

    body = exp[2]
    if body then
      case body.first
      when :lasgn, :iasgn then
        exp[1] << exp.delete_at(2) if body[-1] == s(:gvar, :$!)
      when :block then
        exp[1] << body.delete_at(1) if [:lasgn, :iasgn].include?(body[1][0]) &&
          body[1][-1] == s(:gvar, :$!)
      end
    end

    exp << nil if exp.size == 2 # no body

    exp
  end

  def rewrite_begin(exp)
    raise "wtf: #{exp.inspect}" if exp.size > 2
    exp.last
  end

  def rewrite_vcall(exp)
    exp.push nil
    rewrite_fcall(exp)
  end

  def rewrite_yield(exp)
    # Literal array in yield, not args.
    if exp.size == 3 and exp.pop == true then
      # exp[1] = s(:arglist, exp[1])
    elsif exp.size == 2 && exp.last.first == :array then
      exp.push(*exp.pop[1..-1])
    end

    exp
  end

  def rewrite_super(exp)
    exp.push(*exp.pop[1..-1]) if exp.size == 2 && exp.last.first == :array
    exp
  end

  def rewrite_zarray(exp)
    exp[0] = :array
    exp
  end
end

##
# Quick and easy SexpProcessor that unified the sexp structure.

class Unifier < SexpProcessor
  include UnifiedRuby

  def initialize
    super
    @unsupported.delete :newline
  end
end
