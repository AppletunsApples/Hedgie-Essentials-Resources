class Battle
  alias_method :pbGainExpOne_original, :pbGainExpOne

  def pbGainExpOne(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages = true)
    pbGainExpOne_original(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages)
    0
    # Evolution code
    pkmn = pbParty(0)[idxParty]
    battler = pbFindBattler(idxParty)
    newspecies = pkmn.check_evolution_on_level_up
    return if !newspecies

    old_item = pkmn.item
    pbFadeOutInWithMusic(99999) do
      evo = PokemonEvolutionScene.new
      evo.pbStartScreen(pkmn, newspecies)
      evo.pbEvolution
      evo.pbEndScreen
      if battler
        @scene.pbChangePokemon(@battlers[battler.index], @battlers[battler.index].pokemon)
        battler.name = pkmn.name
      end
    end

    if battler
      # Update battler’s move data and item, if changed
      pkmn.moves.each_with_index do |m, i|
        battler.moves[i] = Battle::Move.from_pokemon_move(self, m)
      end
      battler.pbCheckFormOnMovesetChange

      if pkmn.item != old_item
        battler.item = pkmn.item
        battler.setInitialItem(pkmn.item)
        battler.setRecycleItem(pkmn.item)
      end
    end
  end
end

def pbEndBattle(_result)
    @abortable = false
    pbShowWindow(BLANK)
    # Fade out all sprites
    pbBGMFade(1.0)
    pbFadeOutAndHide(@sprites)
    pbDisposeSprites
    $game_map.autoplay
end