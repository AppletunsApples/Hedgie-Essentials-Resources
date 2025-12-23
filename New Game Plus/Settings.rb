module NewGamePlus
  # Set this to the Game Switch that should be set to ON for New Game+ data
  # to be automatically saved whenever the game saves. Set this to zero if
  # New Game+ data should never save unless explicitly called.
  SAVE_DATA_ON_GAME_SAVE = 100

  # Set this to the Game Switch that should be set to ON for New Game+ data
  # to affect certain events. Set this to zero if New Game+ data should not
  # affect the game besides the party.
  NEW_GAME_PLUS_SWITCH = 101

  # Set this to the amount of money the player starts with upon starting New Game+.
  # If the player had more money than this amount, their money will be unchanged.
  START_MONEY            = 10_000

  # Set this to true if you want the Player's storage Pokemon to also be carried over
  # upon starting New Game+
  CARRY_OVER_STORAGE     = false

  # Set this to true if you want the Player's party Pokemon to be stored in the PC
  # upon starting New Game+. If false, the party Pokemon will be placed in the playe's
  # party instead.
  PARTY_STORED_IN_PC     = true

  # Set this to true if you want the Player's public ID to be carried over upon
  # starting New Game+
  COPY_PLAYER_ID         = false

  # Set this to true if you want the Player's Pokemon's public ID to be carried over
  # upon starting New Game+
  COPY_PKMN_ID           = false

  # Set this to the Level of Pokemon upon starting New Game+
  OVERRIDE_LEVEL         = 5

  # Set this to true to have Pokemon reset to their base forms upon starting New Game+
  OVERRIDE_FORMS         = false

  # Set this to the minimum IVs each Pokemon will have upon starting New Game+
  # Set this to a Hash of IVs for each individual stat, or an Integer to set
  # all stats to the same value. Set it to 0 to leave IVs unchanged.
  # Example:
  # OVERRIDE_IVS = 15
  # OVERRIDE_IVS = {:HP => 20, :DEFENSE => 15, :SPECIAL_ATTACK => 10, :SPEED => 5}
  OVERRIDE_IVS           = 31

  # Set this to the multiplier for the chance of Pokemon being shiny upon starting
  # a New Game+. For example, a value of 100 means a 1 in 100 chance of being shiny.
  # Set this to 0 to leave shiny chances unchanged, and true to make all Pokemon shiny.
  OVERRIDE_SHININESS     = 0

  # Set this to true to reset each Pokemon to their first stage upon starting New Game+
  OVERRIDE_EVOLUTION     = true
end
