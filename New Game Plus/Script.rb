#===============================================================================
# New Game+ by Hedgie
# Carries over Pokémon (base form at level 5) and money while removing items
# Shininess, ability, nature kept, and max IVs set by default
# Adds "New Game+" to the load screen
# Call at a specific spot with NewGamePlus.save_ngplus_data($player).
#===============================================================================
# Core New Game+ Logic
#===============================================================================
module NewGamePlus
  DATA_FILE = "Data/NewGamePlus.dat"
  VERSION = "1"

  def self.ngplus_data_exists?
    File.exist?(DATA_FILE)
  end

  def self.save_ngplus_data(player)
    return false unless player && player.party && !player.party.empty?

    data = {
      name: player.name,
      trainer_type: player.trainer_type,
      money: player.money,
      party: []
    }

    player.party.each do |pkmn|
      next unless pkmn
      data[:party] << {
        species: pkmn.species,
        shiny: pkmn.shiny?,
        ability: pkmn.ability,
        ability_id: pkmn.ability_id,
        nature_id: pkmn.nature_id,
        form: pkmn.form
      }
    end

    begin
      FileUtils.mkdir_p("Data") unless Dir.exist?("Data")
      save_data(data, DATA_FILE)
      true
    rescue
      false
    end
  end

  def self.load_ngplus
    return unless ngplus_data_exists?

    ng_data = load_data(DATA_FILE)
    $game_temp.ngplus_data = ng_data
    pbFadeOutIn do
      Game.start_new
      $PokemonStorage = PokemonStorage.new

      ng_data[:party].each do |pkmn_data|
        next unless pkmn_data[:species]
        species = GameData::Species.try_get(pkmn_data[:species])

        # Determine species
        species_id = species.id
        species_id = species.get_baby_species if NewGamePlusSettings::RESET_PARTY_FIRST_STAGE
        
        new_pkmn = Pokemon.new(species_id, NewGamePlusSettings::START_LEVEL)

        new_pkmn.shiny = NewGamePlusSettings::FORCE_SHINY || pkmn_data[:shiny]
        new_pkmn.nature = pkmn_data[:nature_id] if pkmn_data[:nature_id]
        new_pkmn.form = pkmn_data[:form] if pkmn_data[:form]

        if pkmn_data[:ability_id]
          new_pkmn.ability = pkmn_data[:ability_id]
        end

        iv_value = NewGamePlusSettings::IV_OVERRIDE
        GameData::Stat.each_main { |s| new_pkmn.iv[s.id] = iv_value[s.pbs_order].nil? ? 31 : iv_value[s.pbs_order] }

        new_pkmn.calc_stats
        echoln new_pkmn if $DEBUG
        $player.party << new_pkmn

        $player.party.clear
        $PokemonStorage.pbStoreCaught(new_pkmn)
    end
  end
end

  def self.clear_ngplus_data
    File.delete(DATA_FILE) if File.exist?(DATA_FILE)
  end

  def self.ngplus_data_valid?
    return false unless ngplus_data_exists?

    begin
      data = load_data(DATA_FILE)
      return false unless data.is_a?(Hash)
      return false unless data.key?(:party) && data[:party].is_a?(Array) && !data[:party].empty?

      data[:party].each do |pkmn|
        return false unless pkmn.is_a?(Hash) &&
                            pkmn[:species] &&
                            (pkmn[:species].is_a?(Symbol) || pkmn[:species].is_a?(String))
      end

      return false unless data.key?(:money) && data.key?(:trainer_type)

      true
    rescue
      false
    end
  end

  def self.create_blank_ngplus_data
    data = {
      version: VERSION,
      trainer_type: :POKEMONTRAINER_Red,
      character_ID: 758691,
      money: 3000,
      party: []
    }
    save_data(data, DATA_FILE)
  end
end

# Modify Game_Temp to support NG+ data
class Game_Temp
  attr_accessor :ngplus_data
end

#===============================================================================
# Global helper for event scripts to save NG+ data
#===============================================================================
def prepare_ngplus_data(player = $player)
  return unless player&.party&.any?
  NewGamePlus.save_ngplus_data(player)
end

#===============================================================================
# Add "New Game+" option to Load Screen
#===============================================================================
class PokemonLoadScreen
  alias original_pbStartLoadScreen pbStartLoadScreen
 
  def pbStartLoadScreen
    created_ngplus = false
    if !NewGamePlus.ngplus_data_exists?
    NewGamePlus.create_blank_ngplus_data
    echoln "Blank NG+ data created."
    created_ngplus = true
  end
  
  ngplus_available = created_ngplus || NewGamePlus.ngplus_data_exists?

  cmd_continue      = -1
  cmd_new_game      = -1
  cmd_new_game_plus = -1
  cmd_options       = -1
  cmd_language      = -1
  cmd_mystery_gift  = -1
  cmd_debug         = -1
  cmd_quit          = -1

  commands = []
  show_continue = !@save_data.empty?

  if show_continue
    commands[cmd_continue = commands.length] = _INTL("Continue")
    commands[cmd_mystery_gift = commands.length] = _INTL("Mystery Gift") if @save_data[:player].mystery_gift_unlocked
  end

  commands[cmd_new_game = commands.length] = _INTL("New Game")
  commands[cmd_new_game_plus = commands.length] = _INTL("New Game+") if NewGamePlus.ngplus_data_valid?
  commands[cmd_options = commands.length] = _INTL("Options")
  commands[cmd_language = commands.length] = _INTL("Language") if Settings::LANGUAGES.length >= 2
  commands[cmd_debug = commands.length] = _INTL("Debug") if $DEBUG
  commands[cmd_quit = commands.length] = _INTL("Quit Game")

  map_id = show_continue ? @save_data[:map_factory].map.map_id : 0
  @scene.pbStartScene(commands, show_continue, @save_data[:player], @save_data[:stats], map_id)
  @scene.pbSetParty(@save_data[:player]) if show_continue
  @scene.pbStartScene2

  loop do
    command = @scene.pbChoose(commands)
    pbPlayDecisionSE if command != cmd_quit

    case command
    when cmd_continue
      @scene.pbEndScene
      Game.load(@save_data)
      return
    when cmd_new_game
      @scene.pbEndScene
      Game.start_new
      return
    when cmd_new_game_plus
      @scene.pbEndScene
      NewGamePlus.load_ngplus
      return
    when cmd_mystery_gift
      pbFadeOutIn { pbDownloadMysteryGift(@save_data[:player]) }
    when cmd_options
      pbFadeOutIn do
        scene = PokemonOption_Scene.new
        screen = PokemonOptionScreen.new(scene)
        screen.pbStartScreen
        @save_data[:pokemon_system] = $PokemonSystem
        File.open(SaveData::FILE_PATH, "wb") { |file| Marshal.dump(@save_data, file) }
      end
      $scene = pbCallTitle
      return
    when cmd_language
      pbFadeOutIn do
        $PokemonSystem.language = pbChooseLanguage
        MessageTypes.load_message_files(Settings::LANGUAGES[$PokemonSystem.language][1])
      end
    when cmd_debug
      pbFadeOutIn { pbDebugMenu(false) }
    when cmd_quit
      pbPlayCloseMenuSE
      @scene.pbEndScene
      $scene = nil
      return
    else
      pbPlayBuzzerSE
    end
    end
  end
end

#===============================================================================
# Debug Menu additions scripts to save NG+ data
#===============================================================================
# Add NG+ commands to the debug menu
MenuHandlers.add(:debug_menu, :save_ngplus, {
  "name"        => _INTL("Save NG+ Data"),
  "parent"      => :field_menu,
  "description" => _INTL("Save current party as New Game Plus data."),
  "effect"      => proc {
    if defined?(NewGamePlus) && NewGamePlus.respond_to?(:save_ngplus_data)
      if $player && $player.party.any?
        NewGamePlus.save_ngplus_data($player)
        pbMessage(_INTL("New Game+ data saved from current party."))
      else
        pbMessage(_INTL("No party found to save as NG+ data."))
      end
    else
      pbMessage(_INTL("NG+ save function not found."))
    end
  }
})

MenuHandlers.add(:debug_menu, :clear_ngplus, {
  "name"        => _INTL("Clear NG+ Data"),
  "parent"      => :field_menu,
  "description" => _INTL("Clears all New Game Plus saved data."),
  "effect"      => proc {
    if defined?(NewGamePlus) && NewGamePlus.respond_to?(:clear_ngplus_data)
      NewGamePlus.clear_ngplus_data
      pbMessage(_INTL("New Game+ data cleared successfully."))
    else
      pbMessage(_INTL("NG+ clear function not found."))
    end
  }
})