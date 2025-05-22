class Battle
  
  def pbDebugRun
    return 0 if !$DEBUG || !Input.press?(Input::CTRL)
    commands = [_INTL("Treat as a win"), _INTL("Treat as a loss"),
                _INTL("Treat as a draw"), _INTL("Treat as running away/forfeit")]
    commands.push(_INTL("Treat as a capture")) if wildBattle?
    commands.push(_INTL("Cancel"))
    case pbShowCommands(_INTL("Choose the outcome of this battle."), commands)
    when 0   # Win
      @decision = 1
    when 1   # Loss
      @decision = 2
    when 2   # Draw
      @decision = 5
    when 3   # Run away/forfeit
          pbDisplayPaused(_INTL("Would you like to give up on this battle and quit now?"))
          if pbDisplayConfirm(_INTL("Quitting the battle is the same as losing the battle."))
            @decision = 2   # Treated as a loss
            return 1
          end
    when 4   # Capture
      return -1 if trainerBattle?
      @decision = 4
    else
      return -1
    end
    return 1
  end