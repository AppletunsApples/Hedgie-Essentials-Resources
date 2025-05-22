# to add the weather Ball variant forms changes for Castform
class Battle::Battler

def pbCheckFormOnWeatherChange(ability_changed = false)
    return if fainted? || @effects[PBEffects::Transform]
    # Castform - Forecast
    if isSpecies?(:CASTFORM)
      if hasActiveAbility?(:FORECAST)
        newForm = 0
        case effectiveWeather
        when :Sun, :HarshSun   then newForm = 1
        when :Rain, :HeavyRain then newForm = 2
        when :Hail             then newForm = 3
        end 
        case @pokemon.poke_ball
        when :DROUGHTBALL      then newForm = 1
        when :DRIZZLEBALL      then newForm = 2
        when :HAILBALL         then newForm = 3
        end
        if @form != newForm
          @battle.pbShowAbilitySplash(self, true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(newForm, _INTL("{1} transformed!", pbThis))
        end
      else
        pbChangeForm(0, _INTL("{1} transformed!", pbThis))
      end
    end
    # Cherrim - Flower Gift
    if isSpecies?(:CHERRIM)
      if hasActiveAbility?(:FLOWERGIFT)
        newForm = 0
        newForm = 1 if [:Sun, :HarshSun].include?(effectiveWeather)
        if @form != newForm
          @battle.pbShowAbilitySplash(self, true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(newForm, _INTL("{1} transformed!", pbThis))
        end
      else
        pbChangeForm(0, _INTL("{1} transformed!", pbThis))
      end
    end
    # Eiscue - Ice Face
    if !ability_changed && isSpecies?(:EISCUE) && self.ability == :ICEFACE &&
       @form == 1 && effectiveWeather == :Hail
      @canRestoreIceFace = true   # Changed form at end of round
    end
  end
end