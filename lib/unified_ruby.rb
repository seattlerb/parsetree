
module UnifiedRuby
  def rewrite_bmethod(exp)
    exp[0] = :scope

    args =
      if exp.masgn and exp.masgn.dasgn_curr then
        arg = exp.masgn(true).dasgn_curr(true).sexp_body
        raise "nope: #{arg.size}" unless arg.size == 1
        s(:args, :"*#{arg.last}")
      else
        args = exp.dasgn_curr(true)
        if args then
          s(:args, *args.sexp_body)
        else
          exp.delete_at 1 # nil
          s(:args)
        end
      end

    exp = s(:scope, s(:block, *exp.sexp_body)) unless exp.block
    exp.block.insert 1, args
    exp.find_and_replace_all(:dvar, :lvar)

    exp
  end

  def rewrite_dmethod(exp)
    exp.shift # type
    exp.shift # dmethod name
    exp.shift # scope / block / body
  end

  # s(:defn, :name, s(:scope, s(:block, s(:args, ...), ...)))
  # s(:defn, :name, s(:bmethod, s(:masgn, s(:dasgn_curr, :args)), s(:block, ...)))
  # s(:defn, :name, s(:fbody, s(:bmethod, s(:masgn, s(:dasgn_curr, :params)), s(:block, ...))))
  # =>
  # s(:defn, :name, s(:args, ...), s(:scope, s:(block, ...)))

  def rewrite_defn(exp)
    exp = Sexp.from_array(exp) if Array === exp # HACK for ruby2ruby for now

    # move args up
    args = exp.scope.block.args(true) rescue nil # TODO: remove rescue
    exp.insert 2, args if args

    # move block_arg up and in
    block_arg = exp.scope.block.block_arg(true) rescue nil
    exp.args << block_arg if block_arg

    # patch up attr_accessor methods - WARN might want to remove at some point
    exp.insert 2, s(:args) if exp.ivar or exp.attrset

    exp
  end

  def rewrite_fbody(exp)
    return *exp.sexp_body
  end

  def rewrite_fcall(exp)
    exp[0] = :call
    exp.insert 1, nil
    exp.push nil if exp.size <= 3

    args = exp[-1]
    if Array === args and args.first == :array then
      args[0] = :arglist
    elsif args.nil? then
      exp[-1] = s(:arglist)
    else
      exp[-1] = s(:arglist, args) unless args.nil?
    end

    exp
  end

  def rewrite_vcall(exp)
    exp.push nil
    rewrite_fcall(exp)
  end
end
