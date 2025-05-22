#==============================================================================#
#\\\\\\\\\\\\\\\\\\\\\\\\\\CONFIGURATION\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
#==============================================================================#
LEVEL_CAPS = [15,20,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100]
#==============================================================================#

class Battle
def pbGainExpOne(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages = true)
    pkmn = pbParty(0)[idxParty]   # The Pokémon gaining Exp from defeatedBattler
    growth_rate = pkmn.growth_rate
    # Don't bother calculating if gainer is already at max Exp
    if pkmn.exp >= growth_rate.maximum_exp
      pkmn.calc_stats   # To ensure new EVs still have an effect
      return
    end
    isPartic    = defeatedBattler.participants.include?(idxParty)
    hasExpShare = expShare.include?(idxParty)
    level = defeatedBattler.level
    # Main Exp calculation
    exp = 0
    a = level * defeatedBattler.pokemon.base_exp
    if expShare.length > 0 && (isPartic || hasExpShare)
      if numPartic == 0   # No participants, all Exp goes to Exp Share holders
        exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? expShare.length : 1)
      elsif Settings::SPLIT_EXP_BETWEEN_GAINERS   # Gain from participating and/or Exp Share
        exp = a / (2 * numPartic) if isPartic
        exp += a / (2 * expShare.length) if hasExpShare
      else   # Gain from participating and/or Exp Share (Exp not split)
        exp = (isPartic) ? a : a / 2
      end
    elsif isPartic   # Participated in battle, no Exp Shares held by anyone
      exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? numPartic : 1)
    elsif expAll   # Didn't participate in battle, gaining Exp due to Exp All
      # NOTE: Exp All works like the Exp Share from Gen 6+, not like the Exp All
      #       from Gen 1, i.e. Exp isn't split between all Pokémon gaining it.
      exp = a / 2
    end
    return if exp <= 0
    # Pokémon gain more Exp from trainer battles
    exp = (exp * 1.5).floor if Settings::MORE_EXP_FROM_TRAINER_POKEMON && trainerBattle?
    # Scale the gained Exp based on the gainer's level (or not)
    if Settings::SCALED_EXP_FORMULA
      exp /= 5
      levelAdjust = ((2 * level) + 10.0) / (pkmn.level + level + 10.0)
      levelAdjust **= 5
      levelAdjust = Math.sqrt(levelAdjust)
      exp *= levelAdjust
      exp = exp.floor
      exp += 1 if isPartic || hasExpShare
    else
      exp /= 7
    end
#========EXP CHANGING SCRIPT======================================================================#
    if defined?(pkmn) #check if the pkmn variable exist, for v18 and v19 compatibility
        thispoke = pkmn
    end
    if $game_switches[62] == true
          levelCap=LEVEL_CAPS[$game_variables[27]]
          exp = 50 if pkmn.level>=levelCap || $player.has_exp_all == true && pkmn.level>=levelCap
    elsif $game_switches[61] == true
          levelCap=LEVEL_CAPS[$game_variables[27]]
          exp = 0 if pkmn.level>=levelCap || $player.has_exp_all == true && pkmn.level>=levelCap
      exp = (exp*1)
    end
#==================================================================================================#
    # Foreign Pokémon gain more Exp
    isOutsider = (pkmn.owner.id != pbPlayer.id ||
                 (pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language))
    if isOutsider
      if pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language
        exp = (exp * 1.7).floor
      else
        exp = (exp * 1.5).floor
      end
    end
    # Exp. Charm increases Exp gained
    exp = exp * 3 / 2 if $bag.has?(:EXPCHARM)
    # Modify Exp gain based on pkmn's held item
    i = Battle::ItemEffects.triggerExpGainModifier(pkmn.item, pkmn, exp)
    if i < 0
      i = Battle::ItemEffects.triggerExpGainModifier(@initialItems[0][idxParty], pkmn, exp)
    end
    exp = i if i >= 0
    # Boost Exp gained with high affection
    if Settings::AFFECTION_EFFECTS && @internalBattle && pkmn.affection_level >= 4 && !pkmn.mega?
      exp = exp * 6 / 5
      isOutsider = true   # To show the "boosted Exp" message
    end
    # Make sure Exp doesn't exceed the maximum
    expFinal = growth_rate.add_exp(pkmn.exp, exp)
    expGained = expFinal - pkmn.exp
    return if expGained <= 0
    # "Exp gained" message
    if showMessages
      if isOutsider
        pbDisplayPaused(_INTL("{1} got a boosted {2} Exp. Points!", pkmn.name, expGained))
      else
        pbDisplayPaused(_INTL("{1} got {2} Exp. Points!", pkmn.name, expGained))
      end
    end
    curLevel = pkmn.level
    newLevel = growth_rate.level_from_exp(expFinal)
    if newLevel < curLevel
      debugInfo = "Levels: #{curLevel}->#{newLevel} | Exp: #{pkmn.exp}->#{expFinal} | gain: #{expGained}"
      raise _INTL("{1}'s new level is less than its current level, which shouldn't happen.", pkmn.name) + "\n[#{debugInfo}]"
    end
    # Give Exp
    if pkmn.shadowPokemon?
      if pkmn.heartStage <= 3
        pkmn.exp += expGained
        $stats.total_exp_gained += expGained
      end
      return
    end
    $stats.total_exp_gained += expGained
    tempExp1 = pkmn.exp
    battler = pbFindBattler(idxParty)
    loop do   # For each level gained in turn...
      # EXP Bar animation
      levelMinExp = growth_rate.minimum_exp_for_level(curLevel)
      levelMaxExp = growth_rate.minimum_exp_for_level(curLevel + 1)
      tempExp2 = (levelMaxExp < expFinal) ? levelMaxExp : expFinal
      pkmn.exp = tempExp2
      @scene.pbEXPBar(battler, levelMinExp, levelMaxExp, tempExp1, tempExp2)
      tempExp1 = tempExp2
      curLevel += 1
      if curLevel > newLevel
        # Gained all the Exp now, end the animation
        pkmn.calc_stats
        battler&.pbUpdate(false)
        @scene.pbRefreshOne(battler.index) if battler
        break
      end
      # Levelled up
      pbCommonAnimation("LevelUp", battler) if battler
      oldTotalHP = pkmn.totalhp
      oldAttack  = pkmn.attack
      oldDefense = pkmn.defense
      oldSpAtk   = pkmn.spatk
      oldSpDef   = pkmn.spdef
      oldSpeed   = pkmn.speed
      battler.pokemon.changeHappiness("levelup") if battler&.pokemon
      pkmn.calc_stats
      battler&.pbUpdate(false)
      @scene.pbRefreshOne(battler.index) if battler
      pbDisplayPaused(_INTL("{1} grew to Lv. {2}!", pkmn.name, curLevel)) { pbSEPlay("Pkmn level up") }
      @scene.pbLevelUp(pkmn, battler, oldTotalHP, oldAttack, oldDefense,
                       oldSpAtk, oldSpDef, oldSpeed)
      # Learn all moves learned at this level
      moveList = pkmn.getMoveList
      moveList.each { |m| pbLearnMove(idxParty, m[1]) if m[0] == curLevel }
    end
  end
end

def pbLearnMove(pkmn, move, ignore_if_known = false, by_machine = false, screen = nil, &block)
  return false if !pkmn
  pkmn_name = pkmn.name
  move = GameData::Move.get(move).id
  move_name = GameData::Move.get(move).name
  # Check if Pokémon is unable to learn any moves
  if pkmn.egg? && !$DEBUG
    pbMessage(_INTL("Eggs can't be taught any moves."), &block)
    return false
  elsif pkmn.shadowPokemon?
    pbMessage(_INTL("Shadow Pokémon can't be taught any moves."), &block)
    return false
  end
  # Check if Pokémon can learn this move
  if pkmn.hasMove?(move)
    if !ignore_if_known
      pbMessage(_INTL("{1} already knows {2}.", pkmn_name, move_name), &block)
    end
    return false
  elsif pkmn.numMoves < Pokemon::MAX_MOVES
    pkmn.learn_move(move)
    pbMessage("\\se[]" + _INTL("{1} learned {2}!", pkmn_name, move_name) + "\\se[Pkmn move learnt]", &block)
    return true
  end
  # Pokémon needs to forget a move to learn this one
  pbMessage(_INTL("{1} wants to learn {2}, but it already knows {3} moves.",
                  pkmn_name, move_name, pkmn.numMoves.to_word) + "\1", &block)
  if pbConfirmMessage(_INTL("Should {1} forget a move to learn {2}?", pkmn_name, move_name), &block)
    loop do
      move_index = pbForgetMove(pkmn, move)
      if move_index >= 0
        old_move_name = pkmn.moves[move_index].name
        old_move_pp = pkmn.moves[move_index].pp
        pkmn.moves[move_index] = Pokemon::Move.new(move)   # Replaces current/total PP
        if by_machine && Settings::TAUGHT_MACHINES_KEEP_OLD_PP
          pkmn.moves[move_index].pp = [old_move_pp, pkmn.moves[move_index].total_pp].min
        end
        pbMessage(_INTL("1, 2, and...\\wt[16] ...\\wt[16] ...\\wt[16] Ta-da!") + "\\se[Battle ball drop]\1", &block)
        pbMessage(_INTL("{1} forgot how to use {2}.\nAnd...", pkmn_name, old_move_name) + "\1", &block)
        pbMessage("\\se[]" + _INTL("{1} learned {2}!", pkmn_name, move_name) + "\\se[Pkmn move learnt]", &block)
        pkmn.changeHappiness("machine") if by_machine
        return true
      elsif pbConfirmMessage(_INTL("Give up on learning {1}?", move_name), &block)
        pbMessage(_INTL("{1} did not learn {2}.", pkmn_name, move_name), &block)
        return false
      end
    end
  else
    pbMessage(_INTL("{1} did not learn {2}.", pkmn_name, move_name), &block)
  end
  return false
end

# Exp Candy
def pbGainExpFromExpCandy(pkmn, base_amt, qty, scene, item)
  if pkmn.level >= LEVEL_CAPS[$game_variables[27]] || pkmn.shadowPokemon?
    scene.pbDisplay(_INTL("It won't have any effect."))
    return false
  elsif pkmn.level>LEVEL_CAPS[$game_variables[27]]
    scene.pbDisplay(_INTL("{1} refuses to eat the {2}.", pkmn.name, GameData::Item.get(item).name))
    return false
  end
  max_exp =  pkmn.growth_rate.minimum_exp_for_level(LEVEL_CAPS[$game_variables[27]])
  expected_exp = (base_amt * qty)
  if pkmn.exp + (base_amt * qty) > max_exp
    if scene.pbConfirm(_INTL("{1} will get {2} out of {3} exp. Do you wanna continue?", pkmn.name, max_exp - pkmn.exp, expected_exp))
      pbSEPlay("Pkmn level up")
      pbChangeExp(pkmn, max_exp, scene)
      scene.pbHardRefresh
      return true
    else
      return false
    end
  end
  if qty > 1
    (qty - 1).times { pkmn.changeHappiness("vitamin") }
  end
  pbSEPlay("Pkmn level up")
  pbChangeExp(pkmn, pkmn.exp + expected_exp, scene)
  scene.pbHardRefresh
  return true
end
