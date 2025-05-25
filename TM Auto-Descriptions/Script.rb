#===============================================================================
# TM Auto-Descriptions
# TM move descriptions are automatically generated if the "Description" field in the item's PBS file is left blank (Description =).
#===============================================================================
module GameData
  class Item
    alias :_old_fl_description :description
    def description
      return pbGetMessageFromHash(MessageTypes::MOVE_DESCRIPTIONS, GameData::Move.get(@move).description) if is_machine? #mod
      return _old_fl_description
    end
  end
end