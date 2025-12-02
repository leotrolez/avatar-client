 
function init()
  moreButton = modules.client_topmenu.addRightGameButton('moreButton', tr('Outros'), '/images/topbuttons/more', toggle)
  lootMonster = g_ui.displayUI('lootmonster')
  g_keyboard.bindKeyDown('Escape', lootCancel)
end

function terminate()
  moreButton:destroy()
end

local vocations = {"Fire", "Water", "Air", "Earth"}

function toggle()
  menu = g_ui.createWidget('PopupMenu')
  menu:addOption(tr("Stats"), function() modules.game_playerinfo.requestInformation() --[[g_game.talk("!stats")]] end)
  menu:addOption(tr("Frags"), function() g_game.talk("!frags") end)
  menu:addOption(tr("Tasks"), function() g_game.talk("!tasks") end)
  menu:addOption(tr("Avatar"), function() g_game.talk("!avatar") end)
  menu:addOption(tr("Dominant Guild Castle War"), function() g_game.talk("!dominantguildcastle") end)
  menu:addSeparator()
  menu:addOption("Loot Monster", function() modules.game_monsterloot.toggle()  --[[lootMonster:setVisible(true)]] end)
  menu:addSeparator()
  menu:addOption(tr("Sair da Academia (Ba Sing Se)"), function() g_game.talk("!leaveacademy") end)
  menu:addSeparator()
  menu:addOption("Searcher (exiva)", function() modules.game_console.setTextEditText('Searcher "') end)
  menu:display()
end

function monsterLoot()
  local text = lootMonster:getChildById('monsterLootText'):getText()
  g_game.talk('!loot ' .. text)
  lootMonster:setVisible(false)
end

function lootCancel()
  lootMonster:setVisible(false)
end