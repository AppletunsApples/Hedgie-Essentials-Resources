#===============================================================================
# Default Player Names
# Adds a default name that is not the player's computer username based on gender.
#===============================================================================
#-------------------------------------------------------------------------------
# Overwrites name suggester to be a custom name decided by this plugin rather than the player's PC name.
#-------------------------------------------------------------------------------
def pbSuggestTrainerName(gender)
  if $player&.male? # Change to a variable & number or switch if desired
    return "Eyon" # Male default name
  elsif $player&.female? # Change to a variable & number or switch if desired
    return "Eon" # Female default name
  else
    return "Eos" # Nonbinary if you add it, feel free to remove this
  # Unreachable
#  return getRandomNameEx(gender, nil, 1, Settings::MAX_PLAYER_NAME_SIZE)
end
