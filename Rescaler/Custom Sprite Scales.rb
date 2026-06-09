#-------------------------------------------------------------------------------
# Extensions to the species metrics to allow for custom sprite scaling
#-------------------------------------------------------------------------------
module GameData
  class SpeciesMetrics

    attr_accessor :front_sprite_scale
    attr_accessor :back_sprite_scale

    class << self
      alias __gen8__schema schema unless method_defined?(:__gen8__schema)
    end

    def self.schema
      ret = __gen8__schema
      ret["FrontSpriteScale"] = [:front_sprite_scale, "u"]
      ret["BackSpriteScale"]  = [:back_sprite_scale,  "u"]
      return ret
    end

    def self.get_species_form(species, form)
      return nil if !species || !form
      validate species => [Symbol, String]
      validate form => Integer
      raise _INTL("Undefined species {1}.", species) if !GameData::Species.exists?(species)
      species = species.to_sym if species.is_a?(String)
      if form > 0
        trial = sprintf("%s_%d", species, form).to_sym
        if !DATA.has_key?(trial)
          self.register({ :id => species }) if !DATA[species]
          self.register({
            :id                    => trial,
            :species               => species,
            :form                  => form,
            :back_sprite           => DATA[species].back_sprite.clone,
            :front_sprite          => DATA[species].front_sprite.clone,
            :front_sprite_altitude => DATA[species].front_sprite_altitude,
            :shadow_x              => DATA[species].shadow_x,
            :shadow_size           => DATA[species].shadow_size,
            :front_sprite_scale    => DATA[species].front_sprite_scale,
            :back_sprite_scale     => DATA[species].back_sprite_scale
          })
        end
        return DATA[trial]
      end
      self.register({ :id => species }) if !DATA[species]
      return DATA[species]
    end

    alias __gen8__initialize initialize unless private_method_defined?(:__gen8__initialize)
    def initialize(hash)
      __gen8__initialize(hash)
      @front_sprite_scale = hash[:front_sprite_scale] || Settings::FRONT_BATTLER_SPRITE_SCALE
      @back_sprite_scale  = hash[:back_sprite_scale]  || Settings::BACK_BATTLER_SPRITE_SCALE
    end
  end
end

#-------------------------------------------------------------------------------
# Make sure the pokemon sprite scales are properly compiled
#-------------------------------------------------------------------------------
module GameData
  class << self
    alias __gen8__load_all load_all unless method_defined?(:__gen8__load_all)
  end

  def self.load_all(*args)
    __gen8__load_all(*args)
    return if !$DEBUG
    key = GameData::SpeciesMetrics::DATA.keys.first
    Compiler.compile_pokemon_metrics if GameData::SpeciesMetrics.get(key).front_sprite_scale.nil?
    SpeciesMetrics.load
  end
end
