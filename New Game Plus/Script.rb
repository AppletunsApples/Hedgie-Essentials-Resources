#-------------------------------------------------------------------------------
# New Game+ by Hedgie
# Carries over Pokémon and money while removing items
# Ability and nature are kept. IVs and shininess can be overriden
# Adds "New Game+" to the load screen
# Call from an event with: NewGamePlus.prepare
#-------------------------------------------------------------------------------
# Main module for New Game+ functionality
#-------------------------------------------------------------------------------
module NewGamePlus
  module_function

  FILE_NAME = "NewGamePlus.dat"

  # Returns the path to the NG+ data file
  def self.data_path
    return "#{System.data_directory}#{FILE_NAME}" if File.directory?(System.data_directory)
    return "Data/#{FILE_NAME}"
  end

  # Returns whether the NG+ data file exists
  def exists?; File.exist?(data_path); end

  # Prepares and saves the NG+ data from the current player
  def prepare
    return if !$player || $player.party.empty?
    if save
      echoln(_INTL("New Game+ data has been prepared."))
    else
      echoln(_INTL("Failed to prepare New Game+ data."))
    end
  end

  # Saves the NG+ data from the current player
  def save
    data = {
      name:         $player.name,
      character_ID: $player.character_ID,
      trainer_id:   $player.id,
      money:        $player.money,
      party:        $player.party.map { |pkmn| save_pokemon_data(pkmn) },
      storage:      []
    }
    $PokemonStorage.maxBoxes.times do |i|
      $PokemonStorage.maxPokemon(i).times do |j|
        pkmn = $PokemonStorage[i][j]
        next if !pkmn
        data[:storage] << save_pokemon_data(pkmn)
      end
    end
    begin
      File.open(data_path, "wb") do |file|
        Marshal.dump(data, file)
      end
      return true
    rescue
      return false
    end
  end

  # Returns whether the NG+ data file is valid
  def valid?
    return false if !exists?
    data = nil
    begin
      File.open(data_path, "rb") do |file|
        data = Marshal.load(file)
      end
      return false if !data.is_a?(Hash)
      return false unless data.key?(:money) && data.key?(:character_ID)
      return false if !data[:party].is_a?(Array) || data[:party].empty?
      data[:party].each do |pkmn|
        return false if !pkmn.is_a?(Hash) || !pkmn[:species]
      end
      return true
    rescue
      return false
    end
  end

  # Starts a New Game+ using the NG+ data file
  def start
    return if !valid?
    pbFadeOutIn do
      data = nil
      File.open(data_path, "rb") do |file|
        data = Marshal.load(file)
      end
      $game_temp.ngplus_data = data
      Game.start_new
      switch_id = NewGamePlus::NEW_GAME_PLUS_SWITCH
      $game_switches[switch_id] = true
    end
  end

  # Returns whether the current game is a New Game+
  def started?
    return false if !$PokemonGlobal
    return $PokemonGlobal.in_new_game_plus
  end

  # Deletes the NG+ data file
  def clear
    File.delete(data_path) if exists?
  end

  # Saves Pokemon data into a hash to be stored in NG+ data
  def save_pokemon_data(pkmn)
    return {
      species:       pkmn.species,
      form:          pkmn.form,
      shiny:         pkmn.shiny?,
      ability_index: pkmn.ability_index,
      nature_id:     pkmn.nature_id,
      personal_id:   pkmn.personalID,
      owner:         (pkmn.foreign? || COPY_PLAYER_ID) ? pkmn.owner : nil
    }
  end

  # Loads a Pokemon from saved NG+ data, applying overrides as needed
  def load_pokemon_data(data)
    species_data = GameData::Species.try_get(data[:species])
    return if !species_data
    new_species = (OVERRIDE_EVOLUTION) ? species_data.get_baby_species : species_data.species
    new_pkmn = Pokemon.new(new_species, OVERRIDE_LEVEL)
    new_pkmn.personalID = data[:personal_id] if COPY_PKMN_ID
    new_pkmn.owner = data[:owner] if data[:owner]
    if OVERRIDE_SHININESS.is_a?(Numeric) && OVERRIDE_SHININESS > 0
      new_pkmn.shiny = rand(65_536) < (Settings::SHINY_POKEMON_CHANCE * OVERRIDE_SHININESS)
    elsif NewGamePlus::OVERRIDE_SHININESS == true
      new_pkmn.shiny = true
    end
    new_pkmn.shiny         = true if data[:shiny]
    new_pkmn.form          = data[:form] if !OVERRIDE_FORMS
    new_pkmn.ability_index = data[:ability_index]
    new_pkmn.nature        = data[:nature_id]
    if OVERRIDE_IVS.is_a?(Hash)
      OVERRIDE_IVS.each do |stat, iv_val|
        next if !GameData::Stat.exists?(stat)
        next if !new_pkmn.iv.key?(stat)
        next if !iv_val.is_a?(Numeric)
        iv_val = iv_val.clamp(0, Pokemon::IV_STAT_LIMIT)
        new_pkmn.iv[stat] = [iv_val, new_pkmn.iv[stat]].max
      end
    elsif OVERRIDE_IVS.is_a?(Numeric)
      iv_val = OVERRIDE_IVS.clamp(0, Pokemon::IV_STAT_LIMIT)
      new_pkmn.iv.each { |stat, iv| new_pkmn.iv[stat] = [iv_val, iv].max }
    end
    new_pkmn.calc_stats
    return new_pkmn
  end
end

#-------------------------------------------------------------------------------
# Modify Game.start_new to apply NG+ data on new game start and save
# data when the game is saved
#-------------------------------------------------------------------------------
module Game
  class << self
    alias __ngplus__start_new start_new unless method_defined?(:__ngplus__start_new)
    alias __ngplus__save save unless method_defined?(:__ngplus__save)
  end

  def self.start_new
    __ngplus__start_new
    return if !$game_temp&.ngplus_data
    ng_data = $game_temp.ngplus_data
    $player.instance_variable_set(:@character_ID, ng_data[:character_ID])
    $player.name  = ng_data[:name]
    $player.money = [ng_data[:money], NewGamePlus::START_MONEY].max
    $player.id    = ng_data[:trainer_id] if NewGamePlus::COPY_PLAYER_ID
    ng_data[:party].each do |pkmn_data|
      new_pkmn = NewGamePlus.load_pokemon_data(pkmn_data)
      if NewGamePlus::PARTY_STORED_IN_PC
        $PokemonStorage.pbStoreCaught(new_pkmn)
      else
        $player.party.push(new_pkmn)
      end
    end
    if NewGamePlus::CARRY_OVER_STORAGE
      ng_data[:storage].each do |pkmn|
        next if !pkmn
        new_pkmn = NewGamePlus.load_pokemon_data(pkmn)
        $PokemonStorage.pbStoreCaught(new_pkmn)
      end
    end
    $PokemonGlobal.in_new_game_plus = true
    $game_temp.ngplus_data = nil
  end

  def self.save(*args)
    ret = __ngplus__save(*args)
    switch_id = NewGamePlus::SAVE_DATA_ON_GAME_SAVE
    NewGamePlus.prepare if ret && switch_id > 0 && $game_switches[switch_id]
    return ret
  end
end

#-------------------------------------------------------------------------------
# Add "New Game+" option to Load Screen
#-------------------------------------------------------------------------------
class PokemonLoadScreen
  alias __ngplus__pbStartLoadScreen pbStartLoadScreen unless method_defined?(:__ngplus__pbStartLoadScreen)

  def pbStartLoadScreen
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
    commands[cmd_new_game_plus = commands.length] = _INTL("New Game+") if NewGamePlus.valid?
    commands[cmd_options = commands.length] = _INTL("Options")
    commands[cmd_language = commands.length] = _INTL("Language") if Settings::LANGUAGES.length >= 2
    commands[cmd_debug = commands.length] = _INTL("Debug") if $DEBUG
    commands[cmd_quit = commands.length] = _INTL("Quit Game")
    map_id = (show_continue) ? @save_data[:map_factory].map.map_id : 0
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
        NewGamePlus.start
        return
      when cmd_mystery_gift
        pbFadeOutIn { pbDownloadMysteryGift(@save_data[:player]) }
      when cmd_options
        pbFadeOutIn do
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen
        end
      when cmd_language
        @scene.pbEndScene
        $PokemonSystem.language = pbChooseLanguage
        MessageTypes.load_message_files(Settings::LANGUAGES[$PokemonSystem.language][1])
        if show_continue
          @save_data[:pokemon_system] = $PokemonSystem
          File.open(SaveData::FILE_PATH, "wb") { |file| Marshal.dump(@save_data, file) }
        end
        $scene = pbCallTitle
        return
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

#-------------------------------------------------------------------------------
# Debug options to save and clear NG+ data
#-------------------------------------------------------------------------------
MenuHandlers.add(:debug_menu, :save_ngplus, {
  "name"        => _INTL("Save NG+ Data"),
  "parent"      => :field_menu,
  "description" => _INTL("Saves current New Game Plus data."),
  "effect"      => proc {
    if $player && !$player.party.empty?
      NewGamePlus.save
      pbMessage(_INTL("New Game Plus data saved."))
      if pbConfirmMessage("Would you like to go back to the Titlescreen?")
        $game_temp.title_screen_calling = true
        pbMessage(_INTL("You will be taken to the titlescreen after closing the Pause Menu."))
      end
    else
      pbMessage(_INTL("Your party is empty. Cannot start a New Game Plus."))
    end
  }
})

MenuHandlers.add(:debug_menu, :clear_ngplus, {
  "name"        => _INTL("Clear NG+ Data"),
  "parent"      => :field_menu,
  "description" => _INTL("Clears all New Game Plus data."),
  "effect"      => proc {
    NewGamePlus.clear
    pbMessage(_INTL("New Game+ data cleared successfully."))
  }
})

#-------------------------------------------------------------------------------
# Game_Temp variable to hold NG+ data temporarily
#-------------------------------------------------------------------------------
class PokemonGlobalMetadata
  attr_accessor :in_new_game_plus
end

class Game_Temp
  attr_accessor :ngplus_data
end
