module Settings
  EGGMOVESSWITCH = 99  # Set this switch to toggle the ability to relearn Egg Moves
end

RELEARNABLEEGGMOVES = false  # Set to true to allow relearning Egg Moves.

# This class ensures each Pokémon has an unlocked_relearner flag
class Pokemon
  attr_writer :unlocked_relearner

  # Memorized unlocked_relearner flag
  def unlocked_relearner
    @unlocked_relearner ||= false
  end

  alias_method :old_can_relearn_move?, :can_relearn_move? unless method_defined?(:old_can_relearn_move?)
  
  # Overriding the can_relearn_move? method to check if the Pokémon has relearnable moves
  def can_relearn_move?
    return old_can_relearn_move? && get_relearnable_moves(self).any?
  end
end

# This is the method to check which moves can be relearned, including Egg Moves and First Moves
def get_relearnable_moves(pkmn)
  return [] if !pkmn || pkmn.egg? || pkmn.shadowPokemon?
  moves = []
  
  # Add level-up moves that the Pokémon can relearn
  pkmn.getMoveList.each do |level, move_id|
    next if level > pkmn.level || pkmn.hasMove?(move_id)
    moves.push(move_id) unless moves.include?(move_id)
  end
  
  # Add Egg Moves
  GameData::Species.get(pkmn.species).get_egg_moves.each do |move_id|
    moves.push(move_id) unless pkmn.hasMove?(move_id) || moves.include?(move_id)
  end
  
  # Add First Moves, if enabled via Settings or a switch
  if ($game_switches[Settings::EGGMOVESSWITCH] || RELEARNABLEEGGMOVES) && pkmn.first_moves
    pkmn.first_moves.each do |move_id|
      moves.unshift(move_id) unless pkmn.hasMove?(move_id) || moves.include?(move_id)
    end
  end
  
  # Remove duplicate moves and return the final list
  return moves.uniq
end

# This is the core logic for the Move Relearner NPC event
def move_relearner_npc(pkmn)
  if pkmn.nil?
    pbMessage(_INTL("Come back if you want to relearn a move."))
    return
  end

  if pkmn.egg?
    pbMessage(_INTL("You can't use the Move Relearner on an egg."))
  elsif pkmn.shadowPokemon?
    pbMessage(_INTL("You can't use the Move Relearner on a Shadow Pokémon."))
  elsif pkmn.unlocked_relearner
    if get_relearnable_moves(pkmn).empty?
      pbMessage(_INTL("This Pokémon has no moves to relearn."))
    else
      # Immediately trigger the move relearn screen
      pbRelearnMoveScreen(pkmn)
    end
  else
    # Check if the player has a Heart Scale
    if $bag.has?(:HEARTSCALE)
      if pbConfirmMessage(_INTL("Would you like to use a Heart Scale to unlock the Move Relearner for this Pokémon?"))
        pkmn.unlocked_relearner = true  # Unlock the move relearner
        $bag.remove(:HEARTSCALE)        # Remove the Heart Scale from the bag
        pbMessage(_INTL("This Pokémon can now relearn moves from the party menu."))

        # Trigger the move relearn screen directly after unlocking
        pbRelearnMoveScreen(pkmn)
      end
    else
      pbMessage(_INTL("You need a Heart Scale to unlock move relearning for this Pokémon."))
    end
  end
end

# Adding the Move Relearner option to the Party Menu
MenuHandlers.add(:party_menu, :relearner, {
  "name"      => _INTL("Relearn Moves"),
  "icon_name" => "moves",
  "order"     => 60,
  "condition" => proc { |screen, party, party_idx| 
    pkmn = party[party_idx]
    !pkmn.egg? && !pkmn.shadowPokemon? && pkmn.unlocked_relearner && get_relearnable_moves(pkmn).any?
  },
  "effect"    => proc { |screen, party, party_idx| 
    pkmn = party[party_idx]
    # Automatically unlock the relearner flag when the Move Relearner screen is accessed
    pkmn.unlocked_relearner = true
    pbRelearnMoveScreen(pkmn)
  }
})

# This ensures that the Move Relearner flag is unlocked when the screen is used
class MoveRelearnerScreen
  def pbGetRelearnableMoves(pkmn)
    return get_relearnable_moves(pkmn)
  end

  # Override the pbStartScreen method to automatically unlock the Move Relearner when the screen is opened
  def pbStartScreen(pkmn)
    moves = pbGetRelearnableMoves(pkmn)
    @scene.pbStartScene(pkmn, moves)
    loop do
      move = @scene.pbChooseMove
      if move
        if @scene.pbConfirm(_INTL("Teach {1}?", GameData::Move.get(move).name))
          if pbLearnMove(pkmn, move)
            $stats.moves_taught_by_reminder += 1
            @scene.pbEndScene
            return true
          end
        end
      elsif @scene.pbConfirm(_INTL("Give up trying to teach a new move to {1}?", pkmn.name))
        @scene.pbEndScene
        return false
      end
    end
  end
end

def pbRelearnMoveScreen(pkmn)
  # Ensure that the Pokémon can relearn moves by unlocking the relearner if not already unlocked
  if !pkmn.unlocked_relearner
    pkmn.unlocked_relearner = true  # Unlock the relearner flag when the screen is opened
    pbMessage(_INTL("This Pokémon can now relearn moves from the party menu."))
  end

  retval = true
  pbFadeOutIn do
    scene = MoveRelearner_Scene.new
    screen = MoveRelearnerScreen.new(scene)
    retval = screen.pbStartScreen(pkmn)
  end
  return retval
end


# Ensure the event handler for the Move Relearner NPC is working properly.
def move_relearner_npc(pkmn)
  if pkmn.nil?
    pbMessage(_INTL("Come back if you want to relearn a move."))
    return
  end

  if pkmn.egg?
    pbMessage(_INTL("You can't use the Move Relearner on an egg."))
  elsif pkmn.shadowPokemon?
    pbMessage(_INTL("You can't use the Move Relearner on a Shadow Pokémon."))
  elsif pkmn.unlocked_relearner
    if get_relearnable_moves(pkmn).empty?
      pbMessage(_INTL("This Pokémon has no moves to relearn."))
    else
      # Immediately trigger the move relearn screen
      pbRelearnMoveScreen(pkmn)
    end
  else
    # Check if the player has a Heart Scale
    if $bag.has?(:HEARTSCALE)
      if pbConfirmMessage(_INTL("Would you like to use a Heart Scale to unlock the Move Relearner for this Pokémon?"))
        pkmn.unlocked_relearner = true  # Unlock the move relearner
        $bag.remove(:HEARTSCALE)        # Remove the Heart Scale from the bag
        pbMessage(_INTL("This Pokémon can now relearn moves from the party menu."))

        # Trigger the move relearn screen directly after unlocking
        pbRelearnMoveScreen(pkmn)
      end
    else
      pbMessage(_INTL("You need a Heart Scale to unlock move relearning for this Pokémon."))
    end
  end
end
