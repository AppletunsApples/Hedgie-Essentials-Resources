# Discount Coupon
class PokemonMartAdapter
  alias _hise_getPrice getPrice
  def getPrice(item, selling = false)
    ret = _hise_getPrice(item,selling)
    return ret if selling
    if getInventory.has?(:DISCOUNTCOUPON) && 
       $game_map.metadata&.has_flag?("DiscountCouponUsable")
      min_price = GameData::Item.get(item).sell_price
      if $game_temp.mart_prices && $game_temp.mart_prices[item] &&
         $game_temp.mart_prices[item][1] >= 0
        min_price = $game_temp.mart_prices[item][1]
      end
      discount_price = GameData::Item.get(item).price * 0.6
      ret = [min_price,discount_price].max
    end
    return ret 
  end
end