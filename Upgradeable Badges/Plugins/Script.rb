  def pbDrawTrainerCardFront
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    baseColor   = Color.new(255, 255, 255)
    shadowColor = Color.new(65, 99, 143)
    totalsec = $stats.play_time.to_i
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    time = (hour > 0) ? _INTL("{1}h {2}m", hour, min) : _INTL("{1}m", min)
    $PokemonGlobal.startTime = Time.now if !$PokemonGlobal.startTime
    starttime = _INTL("{1} {2}, {3}",
                      pbGetAbbrevMonthName($PokemonGlobal.startTime.mon),
                      $PokemonGlobal.startTime.day,
                      $PokemonGlobal.startTime.year)
    textPositions = [
      [_INTL("Name"), 34, 70, :left, baseColor, shadowColor],
      [$player.name, 302, 70, :right, baseColor, shadowColor],
      [_INTL("ID No."), 332, 70, :left, baseColor, shadowColor],
      [sprintf("%05d", $player.public_ID), 468, 70, :right, baseColor, shadowColor],
      [_INTL("Money"), 34, 118, :left, baseColor, shadowColor],
      [_INTL("${1}", $player.money.to_s_formatted), 302, 118, :right, baseColor, shadowColor],
      [_INTL("Pokédex"), 34, 166, :left, baseColor, shadowColor],
      [sprintf("%d/%d", $player.pokedex.owned_count, $player.pokedex.seen_count), 302, 166, :right, baseColor, shadowColor],
      [_INTL("Time"), 34, 214, :left, baseColor, shadowColor],
      [time, 302, 214, :right, baseColor, shadowColor],
      [_INTL("Started"), 34, 262, :left, baseColor, shadowColor],
      [starttime, 302, 262, :right, baseColor, shadowColor]
    ]
    pbDrawTextPositions(overlay, textPositions)
    x = 50
    region = pbGetCurrentRegion(0) # Get the current region
    imagePositions = []
    9.times do |i|
      gray_y  = region * 2 * 32
      gold_y  = gray_y + 32
      if $player.badges[i + 9]
        imagePositions.push(["Graphics/UI/Trainer Card/icon_badges", x, 310, i * 32, gold_y, 32, 32]) if $player.badges[i + 9]
      elsif $player.badges[i]
        imagePositions.push(["Graphics/UI/Trainer Card/icon_badges", x, 310, i * 32, gray_y, 32, 32])
      end
      x += 48
    end
    pbDrawImagePositions(overlay, imagePositions)
  end