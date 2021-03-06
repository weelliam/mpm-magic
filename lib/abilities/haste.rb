class Haste < Ability

  def value
    0
  end

  def description
    "This creature is not affected by summoning sickness."
  end

  def when_played(*args)
    card.abilities.reject!{ |a|  a.class == SummoningSickness}
  end

end
