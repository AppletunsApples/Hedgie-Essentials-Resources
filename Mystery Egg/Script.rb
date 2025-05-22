#===============================================================================
# Mystery Egg Plugin by Hedgie
# One-time-per-save egg that hatches into a random Pokémon with custom egg moves.
# Egg hatches after 1 step.
# Call with MysteryEgg.give_mystery_egg
#===============================================================================

module MysteryEgg
  # Define possible Pokémon and their egg moves
  POKEMON_DATA = {
    :TOGEPI   => [:CHARM, :NASTYPLOT],
    :EEVEE    => [:WISH, :YAWN],
    :RIOLU    => [:BULLETPUNCH, :BLAZEKICK],
    :LARVITAR => [:DRAGONDANCE, :OUTRAGE],
    :BAGON    => [:HYDROPUMP, :TWISTER]
  }

  # Main method to give the mystery egg
  def self.give_mystery_egg
    # Pick and save species for this save file
    if !$PokemonGlobal.mysteryEggSpecies
      $PokemonGlobal.mysteryEggSpecies = POKEMON_DATA.keys.sample
    end
    species = $PokemonGlobal.mysteryEggSpecies
    egg_moves = POKEMON_DATA[species]

    # Create the egg
    egg = pbMakeEgg(species)
    if egg
      egg.moves = []  # Remove default moves
      egg_moves.each { |move| egg.learn_move(move) } if egg_moves
      egg.steps_to_hatch = 1  # Hatches after one step
      pbAddPokemonSilent(egg)
      pbMessage("You received a mysterious egg containing #{species.to_s.capitalize}!")
    else
      pbMessage("Failed to create the egg.")
    end
  end
end