local waterNumber = 0
fightOffensiveBox = nil
fightBalancedBox = nil
fightDefensiveBox = nil
chaseModeButton = nil
safeFightButton = nil
fightModeRadioGroup = nil
avatarEdit = true

function doMessageCheck(msg, keyword)
    local a, b = string.find(msg, keyword)

    if(a and b) then
        return true
    end

    return false
end

function string.explode(str, sep, limit)
    local i, pos, tmp, t = 0, 1, "", {}
    
    for s, e in function() return string.find(str, sep, pos) end do
        tmp = str:sub(pos, s - 1):trim()
        table.insert(t, tmp)
        pos = e + 1

        i = i + 1
        if(limit ~= nil and i == limit) then
            break
        end
    end

    tmp = str:sub(pos):trim()
    table.insert(t, tmp)
    
    return t
end

function getPrimaryAndSecondary(msg)
    local strings = string.explode(msg, "#")

    if doMessageCheck(strings[3], ",") then
        local number = string.explode(strings[3], ",")

        return {tonumber(number[1]), tonumber(number[2])}
    else
        return {tonumber(strings[3])}
    end
end

function checkIsWaterMsg(msg)
    local containsW = doMessageCheck(msg, "#w#")

    if containsW then
        local strings = string.explode(msg, ";")

        for x = 1, #strings do
            if doMessageCheck(strings[x], "#w#") then
                local a = getPrimaryAndSecondary(strings[x])
                waterNumber = a[1]
                break
            end
        end

        if inventoryPanel:getChildById('slot10').itemid == 131 then
          refleshNumber()
        else
          refleshNumber(true)
        end

        return true
    end

    return false
end

InventorySlotStyles = {
  [InventorySlotHead] = "HeadSlot",
  [InventorySlotNeck] = "NeckSlot",
  [InventorySlotBack] = "BackSlot",
  [InventorySlotBody] = "BodySlot",
  [InventorySlotRight] = "RightSlot",
  [InventorySlotLeft] = "LeftSlot",
  [InventorySlotLeg] = "LegSlot",
  [InventorySlotFeet] = "FeetSlot",
  [InventorySlotFinger] = "FingerSlot",
  [InventorySlotAmmo] = "AmmoSlot"
}

inventoryWindow = nil
inventoryPanel = nil
inventoryButton = nil



function init()
  connect(LocalPlayer, { 
    onInventoryChange = onInventoryChange,
    onFreeCapacityChange = onFreeCapacityChange
  })

  connect(g_game, { onGameStart = refresh })

  g_keyboard.bindKeyDown('Ctrl+I', toggle)

  inventoryButton = modules.client_topmenu.addRightGameToggleButton('inventoryButton', tr('Inventory') .. ' (Ctrl+I)', '/images/topbuttons/inventory', toggle)
  inventoryButton:setOn(true)

  inventoryWindow = g_ui.loadUI('inventory', modules.game_interface.getRightPanel())
  inventoryWindow:disableResize()
  inventoryPanel = inventoryWindow:getChildById('contentsPanel')


  refresh()

  --alteracoes juntando tudo--
  fightOffensiveBox = inventoryWindow:recursiveGetChildById('fightOffensiveBox')
  fightBalancedBox = inventoryWindow:recursiveGetChildById('fightBalancedBox')
  fightDefensiveBox = inventoryWindow:recursiveGetChildById('fightDefensiveBox')
  chaseModeButton = inventoryWindow:recursiveGetChildById('chaseModeBox')
  safeFightButton = inventoryWindow:recursiveGetChildById('safeFightBox')
  fightModeRadioGroup = UIRadioGroup.create()
  fightModeRadioGroup:addWidget(fightOffensiveBox)
  fightModeRadioGroup:addWidget(fightBalancedBox)
  fightModeRadioGroup:addWidget(fightDefensiveBox)

  connect(fightModeRadioGroup, { onSelectionChange = onSetFightMode })
  connect(chaseModeButton, { onCheckChange = onSetChaseMode })
  connect(safeFightButton, { onCheckChange = onSetSafeFight })
  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
    onFightModeChange = update,
    onChaseModeChange = update,
    onSafeFightChange = update,
    onWalk = check,
    onAutoWalk = check
  })
  --end--

  if g_game.isOnline() then
    local localPlayer = g_game.getLocalPlayer()

    online()
    onFreeCapacityChange(localPlayer, localPlayer:getFreeCapacity())
  end

  inventoryWindow:setup()
end

function refleshNumber(toZero)
  local percentWater = inventoryPanel:getChildById('slot10')

  if not percentWater or waterNumber < 0 then
    return
  end

  if not toZero then
    percentWater:setText(waterNumber.."%")
    percentWater:setColor("white")
    --refresh()
  else
    percentWater:setText()
  end

end

function onFreeCapacityChange(player, freeCapacity)
  inventoryPanel:getChildById('cap'):setText(tr('Cap') .. ': ' .. math.floor(freeCapacity))
end

function terminate()
  if g_game.isOnline() then
    offline()
  end

  disconnect(LocalPlayer, { 
    onInventoryChange = onInventoryChange,
    onFreeCapacityChange = onFreeCapacityChange
  })

  disconnect(g_game, { onGameStart = refresh })

  g_keyboard.unbindKeyDown('Ctrl+I')

  inventoryWindow:destroy()
  inventoryButton:destroy()

  fightModeRadioGroup:destroy()

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
    onFightModeChange = update,
    onChaseModeChange = update,
    onSafeFightChange = update,
    onWalk = check,
    onAutoWalk = check
  })
end

function refresh()
  local player = g_game.getLocalPlayer()
  for i=InventorySlotFirst,InventorySlotLast do
    if g_game.isOnline() then
      onInventoryChange(player, i, player:getInventoryItem(i))
    else
      onInventoryChange(player, i, nil)
    end
  end
end

function toggle()
  if inventoryButton:isOn() then
    inventoryWindow:close()
    inventoryButton:setOn(false)
  else
    inventoryWindow:open()
    inventoryButton:setOn(true)
  end
end

function onMiniWindowClose()
  inventoryButton:setOn(false)
end

-- hooked events
function onInventoryChange(player, slot, item, oldItem)
  if slot >= InventorySlotPurse then return end
  local itemWidget = inventoryPanel:getChildById('slot' .. slot)

  if item then
    itemWidget:setStyle('Item')
    itemWidget:setItem(item)
    itemWidget.itemid = item:getId()
  else
    if slot == 10 then
      refleshNumber(true)
    end
    itemWidget:setStyle(InventorySlotStyles[slot])
    itemWidget:setItem(nil)
  end

end

--alteracoes--

function online()
  local player = g_game.getLocalPlayer()
  if player then
    local char = g_game.getCharacterName()

    local lastCombatControls = g_settings.getNode('LastCombatControls')

    if not table.empty(lastCombatControls) then
      if lastCombatControls[char] then
        g_game.setFightMode(lastCombatControls[char].fightMode)
        g_game.setChaseMode(lastCombatControls[char].chaseMode)
        g_game.setSafeFight(lastCombatControls[char].safeFight)
      end
    end
  end

  update()
end

function offline()
  local lastCombatControls = g_settings.getNode('LastCombatControls')
  if not lastCombatControls then
    lastCombatControls = {}
  end

  local player = g_game.getLocalPlayer()
  if player then
    local char = g_game.getCharacterName()
    lastCombatControls[char] = {
      fightMode = g_game.getFightMode(),
      chaseMode = g_game.getChaseMode(),
      safeFight = g_game.isSafeFight()
    }

    -- save last combat control settings
    g_settings.setNode('LastCombatControls', lastCombatControls)
  end
end

function onSetFightMode(self, selectedFightButton)
  if selectedFightButton == nil then return end
  local buttonId = selectedFightButton:getId()
  local fightMode
  if buttonId == 'fightOffensiveBox' then
    fightMode = FightOffensive
  elseif buttonId == 'fightBalancedBox' then
    fightMode = FightBalanced
  else
    fightMode = FightDefensive
  end
  g_game.setFightMode(fightMode)
end

function onSetChaseMode(self, checked)
  local chaseMode
  if checked then
    chaseMode = ChaseOpponent
  else
    chaseMode = DontChase
  end
  g_game.setChaseMode(chaseMode)
end

function onSetSafeFight(self, checked)
  g_game.setSafeFight(not checked)
end

function update()
  local fightMode = g_game.getFightMode()
  if fightMode == FightOffensive then
    fightModeRadioGroup:selectWidget(fightOffensiveBox)
  elseif fightMode == FightBalanced then
    fightModeRadioGroup:selectWidget(fightBalancedBox)
  else
    fightModeRadioGroup:selectWidget(fightDefensiveBox)
  end

  local chaseMode = g_game.getChaseMode()
  chaseModeButton:setChecked(chaseMode == ChaseOpponent)

  local safeFight = g_game.isSafeFight()
  safeFightButton:setChecked(not safeFight)
end

function check()
  if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
    g_game.setChaseMode(DontChase)
  end
end

--fim--