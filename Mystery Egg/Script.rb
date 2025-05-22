#===============================================================================
# Mystery Egg Plugin by Hedgie
# One-time-per-save egg that hatches into a random Pokémon with custom egg moves.
# Egg hatches after 1 step by default.
# Requires a new save; Call with MysteryEgg::EggGenerator.give_mystery_egg.
#===============================================================================
# Add a new global variable to save the mystery egg species
class PokemonGlobalMetadata
  attr_accessor :mysteryEggSpecies
end

# MysteryEgg module
module MysteryEgg
  # Define possible Pokémon species and their egg moves
  POKEMON_DATA = {
    :TOGEPI   => [:CHARM, :NASTY_PLOT],
    :EEVEE    => [:WISH, :YAWN],
    :RIOLU    => [:BULLET_PUNCH, :BLAZE_KICK],
    :LARVITAR => [:DRAGON_DANCE, :OUTRAGE],
    :BAGON    => [:HYDRO_PUMP, :TWISTER]
  }

  module EggGenerator
    def self.give_mystery_egg
      # Select species if not already chosen
      if !$PokemonGlobal.mysteryEggSpecies
        $PokemonGlobal.mysteryEggSpecies = POKEMON_DATA.keys.sample
      end
      species = $PokemonGlobal.mysteryEggSpecies
      egg_moves = POKEMON_DATA[species]

      # Generate egg
      egg = MysteryEgg.generate_basic_egg(species)
      if egg
        egg.moves = []  # Clear default moves
        egg_moves.each { |move| egg.learn_move(move) } if egg_moves
        egg.steps_to_hatch = 1  # Hatch after 1 step
        pbAddPokemonSilent(egg)
        pbMessage(_INTL("You received a mysterious egg containing {1}!", species.to_s.capitalize))
      else
        pbMessage("Failed to create the egg.")
      end
    end
  end

def self.generate_basic_egg(species_symbol)
  species_data = GameData::Species.try_get(species_symbol)
  return nil if species_data.nil?

  egg = Pokemon.new(species_data.id, Settings::EGG_LEVEL)
  egg.name           = _INTL("Egg")
  egg.steps_to_hatch = species_data.hatch_steps
  egg.obtain_text    = _INTL("Day-Care Couple")
  egg.happiness      = 120
  egg.form           = 0 if species_symbol == :SINISTEA
  # Set regional form
  new_form = MultipleForms.call("getFormOnEggCreation", egg)
  egg.form = new_form if new_form
  return egg
  end
end