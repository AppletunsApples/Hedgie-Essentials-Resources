#===============================================================================
# Script for an abilit-based Pokedex
#-------------------------------------------------------------------------------
# Ability Dex setup
#-------------------------------------------------------------------------------
class PokemonGlobalMetadata
  attr_accessor :ability_dex
end

#-------------------------------------------------------------------------------
# Core Module
#-------------------------------------------------------------------------------
module AbilityDex
  module_function

  def init
    $PokemonGlobal.ability_dex ||= {}
  end

  def data
    init
    $PokemonGlobal.ability_dex
  end

  def register(ability_id, species_id = nil, caught = false)
    return if ability_id.nil?
    dex = data
    dex[ability_id] ||= { seen: true, caught: false, species: [] }
    dex[ability_id][:caught] ||= caught
    if species_id && !dex[ability_id][:species].include?(species_id)
      dex[ability_id][:species] << species_id
    end
  end

  def unlocked?(ability_id)
    data.key?(ability_id)
  end

  def caught?(ability_id)
    return false unless unlocked?(ability_id)
    data[ability_id][:caught]
  end

  def species_for(ability_id)
    return [] unless unlocked?(ability_id)
    data[ability_id][:species]
  end

  def sorted_abilities
    data.keys.sort_by { |a| GameData::Ability.get(a).name }
  end
end

#-------------------------------------------------------------------------------
# Seen abilities
#-------------------------------------------------------------------------------
module AbilityDexHelper
  def self.register(pkmn, caught: false)
    return unless pkmn.is_a?(Pokemon)
    return unless pkmn.species
    return unless pkmn.ability_id
    AbilityDex.register(pkmn.ability_id, pkmn.species, caught)
  end
end

EventHandlers.add(:on_wild_pokemon_created, :abilitydex,
  proc { |pkmn|
    AbilityDexHelper.register(pkmn, caught: false)
  }
)

EventHandlers.add(:on_trainer_load, :abilitydex,
  proc { |trainer|
    next if trainer.nil?
    trainer.party.each do |pkmn|
      AbilityDexHelper.register(pkmn, caught: false)
    end
  }
)

alias abilitydex_pbStorePokemon pbStorePokemon
def pbStorePokemon(pkmn)
  result = abilitydex_pbStorePokemon(pkmn)
  AbilityDexHelper.register(pkmn, caught: true) if pkmn
  return result
end

#-------------------------------------------------------------------------------
# To work in debug
#-------------------------------------------------------------------------------
class Pokemon
  alias abilitydex_initialize initialize
  def initialize(species, level, owner = $player, withMoves = true, recheck_form = true)
    abilitydex_initialize(species, level, owner, withMoves, recheck_form)
    AbilityDex.register(self.ability_id, self.species) if self.ability_id
  end
end

#-------------------------------------------------------------------------------
# Pause Menu
#-------------------------------------------------------------------------------
MenuHandlers.add(:pokegear_menu, :ability_dex, {
  "name"      => _INTL("Abilidex"),
  "icon_name" => "abildex",
  "order"     => 2,
  "condition" => proc { next AbilityDex.data.length > 0 },
  "effect"    => proc {
    pbAbilityDex
    next false
  }
})

#-------------------------------------------------------------------------------
# Screen wrapping
#-------------------------------------------------------------------------------
class AbilityDexScene
  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}

    @sprites["list"] = Window_CommandPokemon.new([])
    @sprites["list"].viewport = @viewport
    @sprites["list"].width  = Graphics.width / 2
    @sprites["list"].height = Graphics.height
    @sprites["list"].x = 0
    @sprites["list"].y = 0

    @sprites["entry"] = Window_AdvancedTextPokemon.new("")
    @sprites["entry"].viewport = @viewport
    @sprites["entry"].x = @sprites["list"].width
    @sprites["entry"].y = 0
    @sprites["entry"].width  = Graphics.width - @sprites["list"].width
    @sprites["entry"].height = Graphics.height

    pbRefreshList
  end

  def pbRefreshList
    @abilities = AbilityDex.sorted_abilities
    @sprites["list"].commands = @abilities.map { |id| GameData::Ability.get(id).name }
    @last_index = -1
    @sprites["list"].index = 0 if @abilities.any?
    pbRefreshEntry
  end

  def pbRefreshEntry
    index = @sprites["list"].index
    return if index < 0
    ability = @abilities[index]
    data    = AbilityDex.data[ability]
    abil    = GameData::Ability.get(ability)

    text = "<b>#{abil.name}</b>\n#{abil.description}"

    if data[:species].any?
      mons = data[:species].map do |s|
        pkmn = GameData::Species.get(s)
        ability_slot = pkmn.abilities.index(ability)
        slot_letter = case ability_slot
                      when 0 then "P"
                      when 1 then "S"
                      else "H"
                      end
        "#{pkmn.name} (#{slot_letter})"
      end
      text += "\n\n<b>Encountered on:</b>\n#{mons.join(', ')}"
    end

    @sprites["entry"].text = text
  end

  def pbMain
    loop do
      Graphics.update
      Input.update
      pbUpdate
      break if Input.trigger?(Input::BACK)
      if @sprites["list"].index != @last_index
        @last_index = @sprites["list"].index
        pbRefreshEntry
      end
    end
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

class AbilityDexScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    begin
      @scene.pbMain
    ensure
      @scene.pbEndScene
    end
  end
end

def pbAbilityDex
  scene  = AbilityDexScene.new
  screen = AbilityDexScreen.new(scene)
  screen.pbStartScreen
end