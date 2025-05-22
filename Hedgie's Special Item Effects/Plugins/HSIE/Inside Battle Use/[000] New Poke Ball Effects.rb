# Geode Ball
Battle::PokeBallEffects::ModifyCatchRate.add(:GEODEBALL, proc { |ball, catchRate, battle, battler|
items=[:FIRESTONE,:WATERSTONE,:THUNDERSTONE,:LEAFSTONE,:MOONSTONE,:SUNSTONE,:DUSKSTONE,:DAWNSTONE,:SHINYSTONE,:ICESTONE]
items.each do |i|
  stone = GameData::Item.try_get(i)
  next unless stone
  if battler.pokemon.species_data.family_item_evolutions_use_item?(stone.id)
    catchRate *= 3
    break
  end
 end
next [catchRate, 255].min
})
