Battle::PokeBallEffects::ModifyCatchRate.add(:SAFARIBALL, proc { |ball, catchRate, battle, battler|
  catchRate *= 2 if $game_map.metadata&.has_flag?("SafariZone")
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:CHERISHBALL, proc { |ball, catchRate, battle, battler|
  catchRate *= 3 if battler.pokemon.species_data.has_flag?("Legendary") || battler.pokemon.species_data.has_flag?("Mythical")
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:SPORTBALL, proc { |ball, catchRate, battle, battler|
  catchRate *= 2.5 if battler.pbHasType?(:BUG) || battler.pbHasType?(:FIGHTING)
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:STRANGEBALL, proc { |ball, catchRate, battle, battler|
  mult = 1  
  player_mons = battle.allSameSideBattlers.select { |b| b.pbOwnedByPlayer? }
  player_mons.each do |pkmn|
    m = 1
    check = (battler.types - pkmn.types)
    if check.empty?
      m = (battler.types.length > 1 ? 4 : 2)
    elsif check.length < battler.types.length
      m = 2
    end
    mult = m if m > mult
  end
  catchRate *= mult
  next catchRate
})
