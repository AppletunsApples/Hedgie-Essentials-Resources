#===============================================================================
# SV Forfeiting
# An update to battling that allows the player to forfeit in battle without the need of debug.
#===============================================================================
class Battle
  
  alias __original_pbRun pbRun

def pbRun(idxBattler, duringBattle = false)
  battler = @battlers[idxBattler]

  if battler.opposes?
    return 0 if trainerBattle?
    @choices[idxBattler][0] = :Run
    @choices[idxBattler][1] = 0
    @choices[idxBattler][2] = nil
    return -1
  end

  if trainerBattle?
    if pbDisplayConfirm(_INTL("Would you like to forfeit the match and quit now?"))
      pbSEPlay("Battle flee")
      pbDisplay(_INTL("{1} forfeited the match!", self.pbPlayer.name))
      @decision = 3
      return 1
    end
    return 0
  end

  __original_pbRun(idxBattler, duringBattle)
  end
end
