def pbMaxUsesOfIVRaisingItem(stat, amt_per_use, pkmn, iv_cap = Pokemon::IV_STAT_LIMIT)
  amt_can_gain = iv_cap - pkmn.iv[stat]
  return [(amt_can_gain.to_f / amt_per_use).ceil, 1].max
end

def pbUseIVRaisingItem(stat, amt_per_use, qty, pkmn, happiness_type, scene, iv_cap = Pokemon::IV_STAT_LIMIT)
  ret = true
  qty.times do |i|
    if pkmn.iv[stat] < iv_cap
      pkmn.iv[stat] = [pkmn.iv[stat] + amt_per_use, 31].min
      pkmn.changeHappiness(happiness_type)
    else
      ret = false if i == 0
      break
    end
  end
  if !ret
    scene.pbDisplay(_INTL("It won't have any effect."))
    return false
  end
  pkmn.calc_stats
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1}'s base {2} increased permanently.", pkmn.name, GameData::Stat.get(stat).name))
  return true
end