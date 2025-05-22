  def crosses_level_cap?
    return ($game_switches[61] || $game_switches[62]) && self.level >= LEVEL_CAPS[pbGet(27)]
  end