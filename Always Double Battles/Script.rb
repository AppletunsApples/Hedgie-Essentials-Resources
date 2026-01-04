#===============================================================================
# Always Double Battles by Hedgie
# Will always force double battles where possible & prevents box usage if the player has 2 or less Pokemon.
#===============================================================================
EventHandlers.add(:on_trainer_load, :doubles_by_default,
   proc { |trainer|
    if pbCanDoubleBattle?
      setBattleRule("double")
    else
      setBattleRule("single")
    end
  }
)

class PokemonEncounters
  def have_double_wild_battle?
    return false if $game_temp.force_single_battle
    return false if pbInSafari?
    return true if $PokemonGlobal.partner
    return true if $player.able_pokemon_count >= 2
    return true
  end
end

#===============================================================================
# Changes to prevent the player from having less than 2 Pokémon once they do.
#===============================================================================
MenuHandlers.add(:pc_menu, :pokemon_storage, {
  "name"      => proc {
    next ($player.seen_storage_creator) ? _INTL("{1}'s PC", pbGetStorageCreator) : _INTL("Someone's PC")
  },
  "order"     => 10,
  "effect"    => proc { |menu|
    pbMessage("\\se[PC access]" + _INTL("The Pokémon Storage System was opened."))
    command = 0
    loop do
      command = pbShowCommandsWithHelp(nil,
                                       [_INTL("Organize Boxes"),
                                        _INTL("Withdraw Pokémon"),
                                        _INTL("Deposit Pokémon"),
                                        _INTL("See ya!")],
                                       [_INTL("Organize the Pokémon in Boxes and in your party."),
                                        _INTL("Move Pokémon stored in Boxes to your party."),
                                        _INTL("Store Pokémon in your party in Boxes."),
                                        _INTL("Return to the previous menu.")], -1, command)
      break if command < 0
      case command
      when 0   # Organize
        pbFadeOutIn do
          scene = PokemonStorageScene.new
          screen = PokemonStorageScreen.new(scene, $PokemonStorage)
          screen.pbStartScreen(0)
        end
      when 1   # Withdraw
        if $PokemonStorage.party_full?
          pbMessage(_INTL("Your party is full!"))
          next
        end
        pbFadeOutIn do
          scene = PokemonStorageScene.new
          screen = PokemonStorageScreen.new(scene, $PokemonStorage)
          screen.pbStartScreen(1)
        end
      when 2   # Deposit
        count = 0
        $PokemonStorage.party.each do |p|
          count += 1 if p && !p.egg? && p.hp > 0
        end
        if count <= 2
          pbMessage(_INTL("Can't deposit one of your last Pokémon!"))
          next
        end
        pbFadeOutIn do
          scene = PokemonStorageScene.new
          screen = PokemonStorageScreen.new(scene, $PokemonStorage)
          screen.pbStartScreen(2)
        end
      else
        break
      end
    end
    next false
  }
})


class PokemonStorageScreen
  def pbStore(selected, heldpoke)
    box = selected[0]
    index = selected[1]
    raise _INTL("Can't deposit from box...") if box != -1
    if pbAbleCount <= 2 && pbAble?(@storage[box, index]) && !heldpoke
      pbPlayBuzzerSE
      pbDisplay(_INTL("Can't deposit one of your last Pokémon!"))
    elsif heldpoke&.mail
      pbDisplay(_INTL("Please remove the Mail."))
    elsif !heldpoke && @storage[box, index].mail
      pbDisplay(_INTL("Please remove the Mail."))
    elsif heldpoke&.cannot_store
      pbDisplay(_INTL("{1} refuses to go into storage!", heldpoke.name))
    elsif !heldpoke && @storage[box, index].cannot_store
      pbDisplay(_INTL("{1} refuses to go into storage!", @storage[box, index].name))
    else
      loop do
        destbox = @scene.pbChooseBox(_INTL("Deposit in which Box?"))
        if destbox >= 0
          firstfree = @storage.pbFirstFreePos(destbox)
          if firstfree < 0
            pbDisplay(_INTL("The Box is full."))
            next
          end
          if heldpoke || selected[0] == -1
            p = (heldpoke) ? heldpoke : @storage[-1, index]
            if Settings::HEAL_STORED_POKEMON
              old_ready_evo = p.ready_to_evolve
              p.heal
              p.ready_to_evolve = old_ready_evo
            end
          end
          @scene.pbStore(selected, heldpoke, destbox, firstfree)
          if heldpoke
            @storage.pbMoveCaughtToBox(heldpoke, destbox)
            @heldpkmn = nil
          else
            @storage.pbMove(destbox, -1, -1, index)
          end
        end
        break
      end
      @scene.pbRefresh
    end
  end

  def pbRelease(selected, heldpoke)
    box = selected[0]
    index = selected[1]
    pokemon = (heldpoke) ? heldpoke : @storage[box, index]
    return if !pokemon
    if pokemon.egg?
      pbDisplay(_INTL("You can't release an Egg."))
      return false
    elsif pokemon.mail
      pbDisplay(_INTL("Please remove the mail."))
      return false
    elsif pokemon.cannot_release
      pbDisplay(_INTL("{1} refuses to leave you!", pokemon.name))
      return false
    end
    if box == -1 && pbAbleCount <= 2 && pbAble?(pokemon) && !heldpoke
      pbPlayBuzzerSE
      pbDisplay(_INTL("That's one of your last Pokémon!"))
      return
    end
    command = pbShowCommands(_INTL("Release this Pokémon?"), [_INTL("No"), _INTL("Yes")])
    if command == 1
      pkmnname = pokemon.name
      @scene.pbRelease(selected, heldpoke)
      if heldpoke
        @heldpkmn = nil
      else
        @storage.pbDelete(box, index)
      end
      @scene.pbRefresh
      pbDisplay(_INTL("{1} was released.", pkmnname))
      pbDisplay(_INTL("Bye-bye, {1}!", pkmnname))
      @scene.pbRefresh
    end
    return
  end

  def pbHold(selected)
    box = selected[0]
    index = selected[1]
    if box == -1 && pbAble?(@storage[box, index]) && pbAbleCount <= 2
      pbPlayBuzzerSE
      pbDisplay(_INTL("That's one of your last Pokémon!"))
      return
    end
    @scene.pbHold(selected)
    @heldpkmn = @storage[box, index]
    @storage.pbDelete(box, index)
    @scene.pbRefresh
  end
end