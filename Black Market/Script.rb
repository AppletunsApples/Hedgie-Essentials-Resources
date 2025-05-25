#-----------------------------------------------------------------------------
# Black Market updated by Hedgie
# A revision of the original Black Market plugin by JT.
# It allows the player to sell Pokemon ala a traditional Mart with the script command pbBlackmarket. 
# Format is either pbBlackMarket[STOCKLISTNAME] with STOCKLISTNAME replaced with the list in the index at the top OR pbBlackMarket([[:SPECIES,COST,LEVEL]]).
#-----------------------------------------------------------------------------
# Predefined stock lists
Pseudo = [
  [:DRATINI, 20000, 10],
  [:LARVITAR, 20000, 12],
  [:BAGON, 20000, 10],
  [:EEVEE, 20000, 12],
  [:BELDUM, 20000, 10],
  [:GIBLE, 20000, 12],
  [:DEINO, 20000, 10],
  [:GOOMY, 20000, 12],
  [:JANGMOO, 20000, 10],
  [:DREEPY, 20000, 12],
  [:FRIGIBAX, 20000, 12],
  # Add more items as needed
]

Starter = [
  [:CHARMANDER, 5000, 8],
  [:SQUIRTLE, 5000, 8],
  # Add more items as needed
]

Legendary= [
  [:MEWTWO, 50000, 50],
  [:MEW, 50000, 50],
  [:ARCEUS, 50000, 50],
  # Add more items as needed
]

def pbBlackmarket(stock, speech = nil)
  for i in 0...stock.length
    species_id = stock[i][0]
    species_data = GameData::Species.get(species_id)
    if !species_data || species_id == 0
      stock[i] = nil
    end
  end
 
  stock.compact!
  commands = []
  cmdBuy = -1
  cmdSell = -1
  cmdQuit = -1
  commands[cmdBuy = commands.length] = _INTL("Buy")
  commands[cmdQuit = commands.length] = _INTL("Quit")
  cmd = pbMessage(
   speech ? speech : _INTL("Welcome! How may I serve you?"), commands, cmdQuit + 1)
loop do
  if cmdBuy >= 0 && cmd == cmdBuy
    scene = Blackmarket_Scene.new
    screen = BlackmarketScreen.new(scene, stock)
    screen.pbBuyScreen
  else
    pbMessage(_INTL("Please come again!"))
    break
  end
  cmd = pbMessage(_INTL("Is there anything else I can help you with?"), commands, cmdQuit + 1)
end

  $game_temp.clear_mart_prices
end

class BlackmarketAdapter
  def initialize(stock)
    @stock = stock
  end

  def getMoney
    return $player.money
  end

  def getMoneyString
    return pbGetGoldString
  end

  def setMoney(value)
    $player.money = value
  end

  def getInventory
    return $player.party
  end

def getDisplayName(item)
  species_data = GameData::Species.get(item)
  return nil unless species_data
 
  species_name = species_data.name
  level = @stock.find { |i| i[0] == item }&.fetch(2, 0)
 
  if level
    return "#{species_name} (Lv. #{level})"
  else
    return species_name
  end
end

  def getName(item)
    return GameData::Species.getName(item)
  end

def getDescription(item)
    if item.nil?
    return _INTL("Quit Shopping")
  else
    species_data = GameData::Species.get(item)
    return nil unless species_data
    description = species_data.pokedex_entry
  return description
  end
end


  def getItemIcon(item)
    return nil if !item
    file = pbCheckPokemonIconFiles([item,nil,nil,nil,nil],nil)
    return AnimatedBitmap.new(file).deanimate
  end

  def getItemIconRect(_item)
    return Rect.new(0,0,64,64)
  end

  def getQuantity(item)
    return nil
  end

  def showQuantity?(item)
    return false
  end

  def getPrice(item,selling=false)
    for i in @stock
      return i[1] if i[0] == item
    end
    return 10000
  end

  def getDisplayPrice(item,selling=false)
    price = getPrice(item,selling).to_s_formatted
    return _INTL("$ {1}",price)
  end

  def canSell?(item)
    return false
  end

  def addItem(item)
  level = 5
  for i in @stock
    level = i[2] if i[0] == item && i[2]
  end
  pokemon = pbGeneratePokemon(item, level)
  return pbAddPokemonSilent(pokemon)
end

  def removeItem(item)
    return nil
  end
end

class BlackmarketScreen < PokemonMartScreen
  def initialize(scene,stock)
    @scene=scene
    @stock=[]
    @adapter=BlackmarketAdapter.new(stock)
    for i in stock
      @stock.push(i.first)
    end
  end
def pbBuyScreen
  @scene.pbStartBuyScene(@stock, @adapter)
  item = 0
  loop do
    item = @scene.pbChooseBuyItem
    quantity = 1
    break if item == 0
    itemname = @adapter.getDisplayName(item)
    price = @adapter.getPrice(item)
    if @adapter.getMoney < price
      pbDisplayPaused(_INTL("You don't have enough money."))
      next
    end
    if !pbConfirm(_INTL("Certainly. You want {1}. That will be ${2}. OK?",
        itemname, price.to_s_formatted))
      next
    end
    unless pbBoxesFull?
      @adapter.setMoney(@adapter.getMoney - price)
      pbDisplayPaused(_INTL("Here you are! Thank you!")) { pbSEPlay("Mart buy item") }
      @adapter.addItem(item)
    else
      pbDisplayPaused(_INTL("You have no more room in the Storage."))
    end
  end
  @scene.pbEndBuyScene
end
end

class Blackmarket_Scene < PokemonMart_Scene
  def pbRefresh
    if @subscene
      @subscene.pbRefresh
    else
      itemwindow = @sprites["itemwindow"]
      @sprites["icon"].species = itemwindow.item
      
      item_description = @adapter.getDescription(itemwindow.item)
      description_text = (item_description.nil? || itemwindow.item == 0) ? _INTL("Quit shopping.") : "<fs=24>#{item_description}</fs>"
      
      @sprites["itemtextwindow"].text = description_text
      itemwindow.refresh
    end
    @sprites["moneywindow"].text = _INTL("Money:\r\n<r>{1}", @adapter.getMoneyString)
  end


  def pbStartBuyOrSellScene(buying,stock,adapter)
    # Scroll right before showing screen
    pbScrollMap(6,5,5)
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @stock=stock
    @adapter=adapter
    @sprites={}
    @sprites["background"]=IconSprite.new(0,0,@viewport)
    @sprites["background"].setBitmap("Graphics/UI/Mart/bg")
    @sprites["icon"]=PokemonSpeciesIconSprite.new(0,@viewport)
    @sprites["icon"].x = 4
    @sprites["icon"].y = Graphics.height-90
    winAdapter=buying ? BuyAdapter.new(adapter) : SellAdapter.new(adapter)
    @sprites["itemwindow"]=Window_PokemonMart.new(stock,winAdapter,
       Graphics.width-316-16,12,330+16,Graphics.height-126)
    @sprites["itemwindow"].viewport=@viewport
    @sprites["itemwindow"].index=0
    @sprites["itemwindow"].refresh
    @sprites["itemtextwindow"]=Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["itemtextwindow"])
    @sprites["itemtextwindow"].x=64
    @sprites["itemtextwindow"].y=Graphics.height-96-16
    @sprites["itemtextwindow"].width=Graphics.width-64
    @sprites["itemtextwindow"].height=128
    @sprites["itemtextwindow"].baseColor=Color.new(248,248,248)
    @sprites["itemtextwindow"].shadowColor=Color.new(0,0,0)
    @sprites["itemtextwindow"].visible=true
    @sprites["itemtextwindow"].viewport=@viewport
    @sprites["itemtextwindow"].windowskin=nil
    @sprites["helpwindow"]=Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["helpwindow"])
    @sprites["helpwindow"].visible=false
    @sprites["helpwindow"].viewport=@viewport
    pbBottomLeftLines(@sprites["helpwindow"],1)
    @sprites["moneywindow"]=Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["moneywindow"])
    @sprites["moneywindow"].setSkin("Graphics/Windowskins/goldskin")
    @sprites["moneywindow"].visible=true
    @sprites["moneywindow"].viewport=@viewport
    @sprites["moneywindow"].x=0
    @sprites["moneywindow"].y=0
    @sprites["moneywindow"].width=190
    @sprites["moneywindow"].height=96
    @sprites["moneywindow"].baseColor=Color.new(88,88,80)
    @sprites["moneywindow"].shadowColor=Color.new(168,184,184)
    pbDeactivateWindows(@sprites)
    @buying=buying
    pbRefresh
    Graphics.frame_reset
  end
  def pbChooseBuyItem
    itemwindow=@sprites["itemwindow"]
    @sprites["helpwindow"].visible=false
    pbActivateWindow(@sprites,"itemwindow") {
      pbRefresh
      loop do
        Graphics.update
        Input.update
        olditem=itemwindow.item
        self.update
        if itemwindow.item!=olditem
          @sprites["icon"].species=itemwindow.item
          @sprites["itemtextwindow"].text=(itemwindow.item==0) ? _INTL("Quit shopping.") :
          "<fs=24>#{@adapter.getDescription(itemwindow.item)}</fs>"
        end
        if Input.trigger?(Input::B)
          pbPlayCloseMenuSE
          return 0
        elsif Input.trigger?(Input::C)
          if itemwindow.index<@stock.length
            pbRefresh
            return @stock[itemwindow.index]
          else
            return 0
          end
        end
      end
    }
  end
end