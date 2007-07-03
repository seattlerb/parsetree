
module UnifiedRuby
#   def rewrite_defs(exp)
#     exp[0] = :defn
#     target = exp.delete_at 1
#     exp[1] = :"#{target}.#{exp[1]}"
#     exp
#   end

  # s(:defn, :name, s(:scope, s(:block, s(:args, ...), ...)))
  # s(:defn, :name, s(:bmethod, s(:masgn, s(:dasgn_curr, :args)), s(:block, ...)))
  # s(:defn, :name, s(:fbody, s(:bmethod, s(:masgn, s(:dasgn_curr, :params)), s(:block, ...))))
  # =>
  # s(:defn, :name, s(:args, ...), s(:scope, s:(block, ...)))

  def rewrite_defn(exp)
    # remove fbody envelope
    exp.push *exp.fbody(true).sexp_body if exp.fbody

    # remove dmethod envelope
    if exp.dmethod then
      exp.delete :dmethod_added
      exp.push *exp.dmethod(true).sexp_body
    end

    # remove bmethod and convert dvars to lvars
    if exp.bmethod then
      exp.push s(:args, *exp.bmethod.dasgn_curr(true).sexp_body)
      exp.push s(:scope, s(:block, *exp.bmethod(true).sexp_body))
      exp.find_and_replace_all(:dvar, :lvar)
    end

    # move args up
    args = exp.scope.block.args(true) rescue nil
    exp.insert 2, args if args

    exp
  end

  def rewrite_fcall(exp)
    exp[0] = :call
    exp.insert 1, nil
    args = exp[-1]
    args[0] = :arglist if Array === args # for :fcall with block (:iter)
    exp
  end

  def rewrite_vcall(exp)
    exp.insert(-1, nil)
    rewrite_fcall(exp)
  end
end
