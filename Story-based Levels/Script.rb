
#===============================================================================
# Overrides stat calculation to use a variable for levels. This means levels effectively are only used for evolutions & level-up moves.
# A new save is needed to get this working.
# Made with help from ChatGPT
#===============================================================================
module Story_LevelStats
  STORY_VAR_ID = 75  # Game variable ID for story progress
  STORY_LEVELS = [5, 10, 15, 20, 25, 30]  # Predefined levels based on story progress

  # Get the current story level based on the variable
  def self.get_story_level
    index = $game_variables[STORY_VAR_ID] || 0  # Default to 0 if invalid
    index = [index, STORY_LEVELS.length - 1].min  # Clamp to max index
    return STORY_LEVELS[index]  # Return the corresponding level from the list
  end

  def self.recalc_all_stats
    # Recalculate stats for Pokémon in the trainer's party
    $player.party.each do |pokemon|
      pokemon.calc_stats  # Force recalculation of stats
    end

    # Recalculate stats for Pokémon in the PC storage (all boxes)
    (0...$PokemonStorage.maxBoxes).each do |box_index|
      next unless $PokemonStorage[box_index]
      $PokemonStorage[box_index].each do |pokemon|
        next unless pokemon
        pokemon.calc_stats
      end
    end
  end
end

#===============================================================================
# Pokemon Class Edits
#===============================================================================
class Pokemon
  alias storylevel_calc_stats calc_stats

  def calc_stats
    if @level.nil? || !self.able?
      return storylevel_calc_stats  # If the Pokémon is not able, return the original stats calculation
    end

    original_level = @level
    new_level = Story_LevelStats.get_story_level  # Get the dynamic story level

    @level = new_level  # Use dynamic story level
    storylevel_calc_stats  # Recalculate stats based on the story level

    @level = original_level  # Restore real level for evolutions and level-up moves
  end
end

#===============================================================================
# Game Variables Class Edits
#===============================================================================
class Game_Variables
  alias storylevel_set_variable []=

  def []=(variable_id, value)
    old_value = self[variable_id]
    storylevel_set_variable(variable_id, value)

    return unless variable_id == Story_LevelStats::STORY_VAR_ID

    if old_value.to_i != value.to_i
      new_story_level = Story_LevelStats.get_story_level
      Story_LevelStats.recalc_all_stats
    else
      # Debug message when the variable value remains the same
      puts "[StoryLevel] Variable #{variable_id} was set to the same value (#{value.inspect}); no recalculation."
    end
  end
end
