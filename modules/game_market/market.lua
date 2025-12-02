
Market = {}

mOpcode = 230
numPage = 0

local marketWindow
local marketWindowAdd
local marketButton
local marketList
local btnNext
local btnPrev
local lblIndex

local function short(value, maxLine)
  if string.len(value) >= maxLine then
    return string.sub(value, 1, maxLine-4) .. " ..."
  else
    return value
  end
end

local function round(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function Market.init()

  connect(g_game, {
    onGameStart = Market.online,
    onGameEnd   = Market.offline
  })
  
  ProtocolGame.registerExtendedOpcode(mOpcode, function(protocol, opcode, buffer)
    local actionAndResult = buffer:explode('>')
	if ( actionAndResult[1] == "create" ) then
	  Market.updateControlsPagination(actionAndResult[2])
      Market.createList(loadstring('return '..actionAndResult[3])()) 
	elseif ( actionAndResult[1] == "details" ) then
      displayInfoBox('Market', actionAndResult[2])
	end  
  end)
  
  marketButton    = modules.client_topmenu.addRightGameButton('marketButton', tr('Market'), '/images/topbuttons/shop', Market.toggle, true)
  marketWindow    = g_ui.displayUI('market')
  marketWindowAdd = g_ui.displayUI('marketadd')
  
  marketList = marketWindow:getChildById('marketList')
  btnNext    = marketWindow:getChildById('btnNext')
  btnPrev    = marketWindow:getChildById('btnPrev')
  lblIndex   = marketWindow:getChildById('lblIndex')
end

function Market.terminate()
  disconnect(g_game, {
    onGameStart = Market.online,
    onGameEnd   = Market.offline
  })
  ProtocolGame.unregisterExtendedOpcode(mOpcode)
  marketButton:destroy()
  marketWindow:destroy()
  marketWindowAdd:destroy()
end

function Market.online()
  numPage = g_settings.getNumber('mNumPage', 1)
  g_game.getProtocolGame():sendExtendedOpcode(mOpcode, "getOffer>"..numPage) 
end

function Market.offline()
  marketWindow:hide()
  g_settings.set('mNumPage', numPage)
end

function Market.toggle()
  marketWindow:setVisible(not marketWindow:isVisible())
end

function Market.showAddOffer()
  if ( not marketWindowAdd:isVisible() ) then
    marketWindowAdd:show()
	marketWindowAdd:focus()
	marketWindowAdd:raise()
  end
end

function Market.addOffer()
  local itemName  = marketWindowAdd:getChildById('edtItem')
  local itemPrice = marketWindowAdd:getChildById('edtPrice')
  local itemCount = marketWindowAdd:getChildById('edtCount')
  
  local action = string.format("!offer add, %s, %s, %s", itemName:getText(), itemCount:getText(), itemPrice:getText()) 
  g_game.talkChannel(MessageModes.Market, MessageModes.None, action)
  g_game.getProtocolGame():sendExtendedOpcode(mOpcode, "getOffer>"..numPage)

  itemName:clearText()
  itemPrice:clearText()
  itemCount:clearText()
  marketWindowAdd:hide()
end

function Market.createList(list)
  marketList:destroyChildren()
  for i, value in pairs(list) do
    local marketRow = g_ui.createWidget('MarketRow', marketList)
	
	marketRow.onDoubleClick = function(self) g_game.getProtocolGame():sendExtendedOpcode(mOpcode, "details>"..value.id)	end
	
	marketRow:getChildById('uiItem'):setItemId(value.itemId)
	marketRow:getChildById('lblItem'):setText(short(value.itemName, 23))
	marketRow:getChildById('lblPlayer'):setText(short(value.player, 25))
	marketRow:getChildById('lblQtd'):setText(value.count)
	marketRow:getChildById('lblPrice'):setText(round(value.price/1000, 2).."k")
	
	local btnAction = marketRow:getChildById('btnAction')
	btnAction:setText(value.type == 0 and "Comprar Item" or "Remover Oferta")
	btnAction.onClick = function(self)
	  local action = (value.type == 0 and "!offer buy," or "!offer remove,")..value.id
	  g_game.talkChannel(MessageModes.Market, MessageModes.None, action)
	  g_game.getProtocolGame():sendExtendedOpcode(mOpcode, "getOffer>"..numPage)
	end
  end
end

function Market.nextAndPrev(control)
  numPage = ( control == 1 ) and ( numPage + 1 ) or ( numPage - 1 )
  g_game.getProtocolGame():sendExtendedOpcode(mOpcode, "getOffer>"..numPage)  
end

function Market.updateControlsPagination(value)
  btnPrev:setEnabled((numPage ~= 1))
  btnNext:setEnabled((numPage < math.ceil(value/15)))
  lblIndex:setText('Page: '..numPage..'/'..math.ceil(value/15))
end
