class Haste < Ability

  def description
    "This creature does extra player dommage when blocked"
  end

  def when_blocked
    card.abilities.reject!{ |a|  a.class == SummoningSickness}
  end

end
