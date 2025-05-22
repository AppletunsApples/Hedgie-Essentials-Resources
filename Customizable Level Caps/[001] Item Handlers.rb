#==================================================================================================#
# Item Handlers
#==================================================================================================#
ItemHandlers::UseOnPokemonMaximum.add(:COMMONCANDY, proc { |item, pkmn|
  if ($game_switches[61] || $game_switches[62])
  max_lv = $game_switches[62] ? $game_variables[27] : GameData::GrowthRate.max_level
  next max_lv - pkmn.level
  else
    next GameData::GrowthRate.max_level - pkmn.level
  end
})

ItemHandlers::UseOnPokemon.add(:COMMONCANDY, proc { |item, qty, pkmn, scene|
  if pkmn.shadowPokemon?
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  elsif pkmn.level >= GameData::GrowthRate.max_level
    new_species = pkmn.check_evolution_on_level_up
    if !Settings::RARE_CANDY_USABLE_AT_MAX_LEVEL || !new_species
      scene.pbDisplay(_INTL("It won't have any effect."))
      next false
    end
    # Check for evolution
    pbFadeOutInWithMusic do
      evo = PokemonEvolutionScene.new
      evo.pbStartScreen(pkmn)
      evo.pbEvolution
      evo.pbEndScreen
      scene.pbRefresh if scene.is_a?(PokemonPartyScreen)
    end
    next true
  elsif ($game_switches[61] || $game_switches[62]) && pkmn.level + qty > LEVEL_CAPS[$game_variables[27]]
    scene.pbDisplay(_INTL("{1} refuses to eat the {2}.", pkmn.name, GameData::Item.get(item).name))
    next false
  end
  # Level up
  pbSEPlay("Pkmn level up")
  pbChangeLevel(pkmn, pkmn.level + qty, scene)
  scene.pbHardRefresh
  next true
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYXS, proc { |item, pkmn|
  gain_amount = 100
  max_exp = LEVEL_CAPS[$game_variables[27]] ? pkmn.growth_rate.minimum_exp_for_level($game_variables[27]) : pkmn.growth_rate.maximum_exp if ($game_switches[61] || $game_switches[62])
  next ((pkmn.growth_rate.maximum_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYXS, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 100, qty, scene, item)
 })

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYS, proc { |item, pkmn|
  gain_amount = 800
  max_exp = LEVEL_CAPS[$game_variables[27]] ? pkmn.growth_rate.minimum_exp_for_level($game_variables[27]) : pkmn.growth_rate.maximum_exp if ($game_switches[61] || $game_switches[62])
  next ((pkmn.growth_rate.maximum_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYS, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 800, qty, scene, item)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYM, proc { |item, pkmn|
  gain_amount = 3_000
  max_exp = LEVEL_CAPS[$game_variables[27]] ? pkmn.growth_rate.minimum_exp_for_level($game_variables[27]) : pkmn.growth_rate.maximum_exp if ($game_switches[61] || $game_switches[62])
  next ((pkmn.growth_rate.maximum_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYM, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 3_000, qty, scene, item)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYL, proc { |item, pkmn|
  gain_amount = 10_000
  max_exp = LEVEL_CAPS[$game_variables[27]] ? pkmn.growth_rate.minimum_exp_for_level($game_variables[27]) : pkmn.growth_rate.maximum_exp if ($game_switches[61] || $game_switches[62])
  next ((pkmn.growth_rate.maximum_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYL, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 10_000, qty, scene, item)
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYXL, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 30_000, qty, scene, item)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYXL, proc { |item, pkmn|
 gain_amount = 30_000
 max_exp = LEVEL_CAPS[$game_variables[27]] ? pkmn.growth_rate.minimum_exp_for_level($game_variables[27]) : pkmn.growth_rate.maximum_exp if ($game_switches[61] || $game_switches[62])
 next ((pkmn.growth_rate.maximum_exp - pkmn.exp) / gain_amount.to_f).ceil
})

# Notebook
ItemHandlers::UseInField.add(:NOTEBOOK, proc { |item|
  pbMessage(_INTL("The current level cap is {1}.", LEVEL_CAPS[$game_variables[27]]))
   next 1
})

ItemHandlers::UseFromBag.add(:NOTEBOOK, proc { |item, bag_screen|
  pbMessage(_INTL("The current level cap is {1}.", LEVEL_CAPS[$game_variables[27]]))
   next 1
})