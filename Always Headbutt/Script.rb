def pbIsHeadbuttAlways?
  return true
end

alias headbutt_effect_always pbHeadbuttEffect
def pbHeadbuttEffect(event = nil)
  if pbIsHeadbuttAlways?
    pbHeadbuttEffectAlways
  else
    headbutt_effect_always(event)
  end
end

def pbHeadbuttEffectAlways
  enctype = (rand(100) < 15 ? :HeadbuttLow : :HeadbuttHigh)
  if pbEncounter(enctype)
    $stats.headbutt_battles += 1
  else
    pbMessage(_INTL("Nope. Nothing..."))
  end
end