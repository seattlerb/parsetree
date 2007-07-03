
module UnifiedRuby
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
