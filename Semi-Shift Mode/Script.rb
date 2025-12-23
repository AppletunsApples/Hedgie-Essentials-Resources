#-------------------------------------------------------------------------------
# Pokémon System option storage
#-------------------------------------------------------------------------------
class PokemonSystem
  attr_accessor :battlestyle

  alias __semiswitch_init initialize
  def initialize
    __semiswitch_init
    @battlestyle = 0 if @battlestyle.nil?
  end
end

#-------------------------------------------------------------------------------
# Options Menu entry
#-------------------------------------------------------------------------------
MenuHandlers.add(:options_menu, :battle_style, {
  "name"        => _INTL("Battle Style"),
  "order"       => 50,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Switch"), _INTL("Semi-Switch"), _INTL("Set")],
  "description" => _INTL("Choose whether you can switch Pokémon when an opponent faints."),
  "get_proc"    => proc { next $PokemonSystem.battlestyle || 0 },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.battlestyle = value }
})

#-------------------------------------------------------------------------------
# Battle accessors
#-------------------------------------------------------------------------------
class Battle
  attr_accessor :switchStyle
  attr_accessor :semiswitchStyle
end

#-------------------------------------------------------------------------------
# Battle rule handling & prepare_battle
#-------------------------------------------------------------------------------
class Game_Temp
  def add_battle_rule(rule, _var = nil)
    rules = self.battle_rules
    case rule.to_s.downcase
    when "switchstyle"
      rules["switchStyle"] = true
      rules["semiswitchStyle"] = false
    when "semiswitchstyle"
      rules["switchStyle"] = false
      rules["semiswitchStyle"] = true
    when "setstyle"
      rules["switchStyle"] = false
      rules["semiswitchStyle"] = false
    end
  end

  # Safe prepare_battle method
  def prepare_battle(battle)
    rules = self.battle_rules

    # Apply rules or options
    battle.switchStyle =
      rules.key?("switchStyle") ? rules["switchStyle"] : ($PokemonSystem.battlestyle == 0)
    battle.semiswitchStyle =
      rules.key?("semiswitchStyle") ? rules["semiswitchStyle"] : ($PokemonSystem.battlestyle == 1)

    style =
      if battle.switchStyle
        "Switch"
      elsif battle.semiswitchStyle
        "Semi-Switch"
      else
        "Set"
      end
    end
  end

#-------------------------------------------------------------------------------
# Ensure prepare_battle is called at battle start & EORSwitch SS prompt
#-------------------------------------------------------------------------------
class Battle
  alias __semiswitch_pbStartBattle_orig pbStartBattle
  def pbStartBattle
    $game_temp.prepare_battle(self) if $game_temp
    __semiswitch_pbStartBattle_orig
  end
end

class Battle
  def pbEORSwitch(favorDraws = false)
    return if @decision > 0 && !favorDraws
    return if @decision == 5 && favorDraws
    pbJudge
    return if @decision > 0
    # Check through each fainted battler to see if that spot can be filled.
    switched = []
    loop do
      switched.clear
      @battlers.each do |b|
        next if !b || !b.fainted?
        idxBattler = b.index
        next if !pbCanChooseNonActive?(idxBattler)
        if !pbOwnedByPlayer?(idxBattler)   # Opponent/ally is switching in
          next if b.wild?   # Wild Pokémon can't switch
          idxPartyNew = pbSwitchInBetween(idxBattler)
          opponent = pbGetOwnerFromBattlerIndex(idxBattler)
          # NOTE: The player is only offered the chance to switch their own
          #       Pokémon when an opponent replaces a fainted Pokémon in single
          #       battles. In double battles, etc. there is no such offer.
          if @internalBattle && @switchStyle && trainerBattle? && pbSideSize(0) == 1 &&
             opposes?(idxBattler) && !@battlers[0].fainted? && !switched.include?(0) &&
             pbCanChooseNonActive?(0) && @battlers[0].effects[PBEffects::Outrage] == 0
            idxPartyForName = idxPartyNew
            enemyParty = pbParty(idxBattler)
            if enemyParty[idxPartyNew].ability == :ILLUSION && !pbCheckGlobalAbility(:NEUTRALIZINGGAS)
              new_index = pbLastInTeam(idxBattler)
              idxPartyForName = new_index if new_index >= 0 && new_index != idxPartyNew
            end
            if pbDisplayConfirm(_INTL("{1} is about to send out {2}. Will you switch your Pokémon?",
                                      opponent.full_name, enemyParty[idxPartyForName].name))
              idxPlayerPartyNew = pbSwitchInBetween(0, false, true)
              if idxPlayerPartyNew >= 0
                pbMessageOnRecall(@battlers[0])
                pbRecallAndReplace(0, idxPlayerPartyNew)
                switched.push(0)
              end
            end
          end
        # Semi-Switch style logic
         if @internalBattle && @semiswitchStyle && trainerBattle? && pbSideSize(0) == 1 &&
             opposes?(idxBattler) && !@battlers[0].fainted? && !switched.include?(0) &&
             pbCanChooseNonActive?(0) && @battlers[0].effects[PBEffects::Outrage] == 0
            idxPartyForName = idxPartyNew
            enemyParty = pbParty(idxBattler)
            if enemyParty[idxPartyNew].ability == :ILLUSION && !pbCheckGlobalAbility(:NEUTRALIZINGGAS)
              new_index = pbLastInTeam(idxBattler)
              idxPartyForName = new_index if new_index >= 0 && new_index != idxPartyNew
            end
            if pbDisplayConfirm(_INTL("{1} is about to send out a new Pokémon. Will you switch your Pokémon?",
                                      opponent.full_name))
              idxPlayerPartyNew = pbSwitchInBetween(0, false, true)
              if idxPlayerPartyNew >= 0
                pbMessageOnRecall(@battlers[0])
                pbRecallAndReplace(0, idxPlayerPartyNew)
                switched.push(0)
              end
            end
          end
          pbRecallAndReplace(idxBattler, idxPartyNew)
          switched.push(idxBattler)
        elsif trainerBattle?   # Player switches in in a trainer battle
          idxPlayerPartyNew = pbGetReplacementPokemonIndex(idxBattler)   # Owner chooses
          pbRecallAndReplace(idxBattler, idxPlayerPartyNew)
          switched.push(idxBattler)
        else   # Player's Pokémon has fainted in a wild battle
          switch = false
          if pbDisplayConfirm(_INTL("Use next Pokémon?"))
            switch = true
          else
            switch = (pbRun(idxBattler, true) <= 0)
          end
          if switch
            idxPlayerPartyNew = pbGetReplacementPokemonIndex(idxBattler)   # Owner chooses
            pbRecallAndReplace(idxBattler, idxPlayerPartyNew)
            switched.push(idxBattler)
          end
        end
      end
      break if switched.length == 0
      pbOnBattlerEnteringBattle(switched)
    end
  end
end