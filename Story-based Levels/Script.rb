#===============================================================================
# Story-based Levels by Hedgie
# The level used in battle is linked to a variable that determines the level at which the Pokémon's stats are calculated.
# This means levels effectively are only used for evolutions & level-up moves.
# To safely update old saves, use the following script commands somewhere:
# pbSetStoryLevel(#)
#===============================================================================
module Story_LevelStats
  def self.get_story_level
    index = $game_variables[Settings::STORY_VARIABLE] || 0  # Default to var. 0 if invalid
    index = [index, Settings::STORY_LEVELS.length - 1].min 
    return Settings::STORY_LEVELS[index]
  end

  def self.recalc_all_stats
    $player.party.each do |pokemon|
      pokemon.calc_stats
    end
    (0...$PokemonStorage.maxBoxes).each do |box_index|
      next unless $PokemonStorage[box_index]
      $PokemonStorage[box_index].each do |pokemon|
        next unless pokemon
        pokemon.calc_stats
      end
    end
  end
end

  def pbSetStoryLevel(value)
    $game_variables[Settings::STORY_VARIABLE] = value
    Story_LevelStats.recalc_all_stats
  end

#-------------------------------------------------------------------------------
# Party UI
#-------------------------------------------------------------------------------
class Pokemon
  def story_level
    Story_LevelStats.get_story_level
  end
end

  def baseStats
    this_base_stats = species_data.base_stats
    ret = {}
    GameData::Stat.each_main { |s| ret[s.id] = this_base_stats[s.id] }
     lvl = respond_to?(:story_level) ? story_level : level
    return ret
  end


#-------------------------------------------------------------------------------
# Debug Menu
#-------------------------------------------------------------------------------
MenuHandlers.add(:debug_menu, :story_level_debug, {
  "name"        => _INTL("Story Levels"),
  "parent"      => :field_menu,
  "description" => _INTL("Toggle Story Level options."),
  "effect"      => proc {
  commands = [
    _INTL("Set Story Variable"),
    _INTL("Recalculate All Stats"),
    _INTL("Show Current Story Level"),
    _INTL("Exit")
  ]

  loop do
    cmd = pbShowCommands(nil, commands)
    case cmd
    when 0
      params = ChooseNumberParams.new
      params.setRange(0, Settings::STORY_LEVELS.length - 1) # index in story levels
      current_index = $game_variables[Settings::STORY_VARIABLE] || 0
      params.setDefaultValue(current_index)
      index = pbMessageChooseNumber(
        _INTL("Set the Story Level (max. {1}).", Settings::STORY_LEVELS.last), params)
      if index != current_index
        $game_variables[Settings::STORY_VARIABLE] = index
        Story_LevelStats.recalc_all_stats
      end
    when 1
      Story_LevelStats.recalc_all_stats
      pbMessage(_INTL("All party and storage Pokémon stats recalculated."))
    when 2
      level = Story_LevelStats.get_story_level
      pbMessage(_INTL("Current Story Level: {1}", level))
    when 3
      break
    end
  end
  next false
  }
})

#===============================================================================
# Pokemon Class Edits
#===============================================================================
class Pokemon
  alias storylevel_calc_stats calc_stats

  def calc_stats
    if @level.nil? || !self.able?
      return storylevel_calc_stats
    end

    original_level = @level
    new_level = Story_LevelStats.get_story_level
    
    @level = new_level
    storylevel_calc_stats

    @level = original_level  # Restore real level for evolutions and level-up moves
  end
end

#===============================================================================
# Game Variables Edits
#===============================================================================
class Game_Variables
  alias storylevel_set_variable []=

  def []=(variable_id, value)
    old_value = self[variable_id]
    storylevel_set_variable(variable_id, value)
    return unless variable_id == Settings::STORY_VARIABLE
    if old_value.to_i != value.to_i
      $game_variables[Settings::STORY_VARIABLE] = value.to_i
      Story_LevelStats.recalc_all_stats
      new_story_level = Settings::STORY_LEVELS[$game_variables[Settings::STORY_VARIABLE]]
      puts "Variable #{Settings::STORY_VARIABLE} was set to Level #{new_story_level}; Stats have been recalculated."
    end
  end
end
