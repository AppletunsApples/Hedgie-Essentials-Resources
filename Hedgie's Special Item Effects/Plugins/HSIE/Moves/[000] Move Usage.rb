  Battle::ItemEffects::AfterMoveUseFromUser.add(:LOOPHOLE,
  proc { |item, user, targets, move, numHits, battle|
    if target.isSpecies?(:HOOPA) && pkmn.form = 0
       # Record that Loop Hole applies, to weaken the second attack
        user.effects[PBEffects::ParentalBond] = 3
        return 2
      end
      return 1
  }
)
