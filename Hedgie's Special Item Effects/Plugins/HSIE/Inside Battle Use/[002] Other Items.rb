# Thumb Drive
Battle::ItemEffects::SpeedCalc.add(:THUMBDRIVE,
  proc { |item, battler, mult|
  next mult * 1.5 if (user.isSpecies?(:PORYGON) || user.isSpecies?(:PORYGON2) || user.isSpecies?(:PORYGONZ))
  }
)

# Gold Teeth
Battle::ItemEffects::DamageCalcFromUser.add(:GOLDTEETH,
  proc { |item, user, target, move, mults, baseDmg, type|
    mults[:power_multiplier] *= 1.1 if move.bitingMove?
  }
)

# LGPE Items
Battle::ItemEffects::DamageCalcFromUser.add(:BEACHGLASS,
  proc { |item, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.15 if type == :STEEL
  }
)

Battle::ItemEffects::DamageCalcFromUser.copy(:BEACHGLASS, :STRETCHYSTRING)

Battle::ItemEffects::DamageCalcFromUser.add(:BEACHGLASS,
  proc { |item, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.15 if type == :WATER
  }
)

Battle::ItemEffects::DamageCalcFromUser.copy(:BEACHGLASS, :TROPICALSHELL)

Battle::ItemEffects::DamageCalcFromUser.add(:CHALKYSTONE,
  proc { |item, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.15 if type == :ROCK
  }
)

Battle::ItemEffects::DamageCalcFromUser.copy(:CHALKYSTONE, :POLISHEDMUDBALL, :TROPICALSHELL)

Battle::ItemEffects::DamageCalcFromUser.add(:CHALKYSTONE,
  proc { |item, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.15 if type == :NORMAL
  }
)

Battle::ItemEffects::DamageCalcFromUser.copy(:CHALKYSTONE, :SILVERLEAF, :STRETCHYSTRING)

Battle::ItemEffects::DamageCalcFromUser.add(:SMALLBOUQUET,
  proc { |item, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.15 if type == :FAIRY
  }
)

Battle::ItemEffects::DamageCalcFromUser.add(:POLISHEDMUDBALL,
  proc { |item, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.15 if type == :GROUND
  }
)

Battle::ItemEffects::DamageCalcFromUser.add(:SILVERLEAF,
  proc { |item, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.15 if type == :GRASS
  }
)

Battle::ItemEffects::DamageCalcFromUser.copy(:SILVERLEAF, :SMALLBOUQUET)

Battle::ItemEffects::DamageCalcFromUser.add(:MIRACLESEED,
  proc { |item, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.2 if type == :GRASS
  }
)

Battle::ItemEffects::DamageCalcFromUser.copy(:MIRACLESEED, :MEADOWPLATE, :ROSEINCENSE, :GOLDLEAF)
