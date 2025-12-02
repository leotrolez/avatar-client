spellBarPanel = nil
spellBarBox = nil
cooldown = {}

CALLBACK_COOLDOWN_UPDATE = 1
CALLBACK_COOLDOWN_FINISH = 2

local MAX_SLOTS = 12

local function formatTime(time)
	local seconds = time % 600
    local minutes = math.floor(time / 60)

	local to_return = ''
    if seconds < 10 then
        to_return = tostring(seconds)
        to_return = to_return:find('%.') and to_return or to_return .. '.0'
    else
        to_return = tostring(math.floor(seconds)) .. 's'
    end

    if minutes >= 10 then
        to_return = tostring(math.floor(minutes)) .. 'm'
	end
	return to_return
end

function sendUpdateSpellBar()
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(ExtendedIds.PlayerSpells)
    end
end

function updateWeaponSpells(skill1, skill2)
    local info = skill1 and WeaponInfo[skill1]
    weaponSkill1:setImageSource(info and info.icon or '/images/game/spelltree/spell_00')
    weaponSkill1:setTooltip(info and (skill1 .. '\n\n' .. info.description) or '')
    if info then
        if weaponSkill1.hotkey then
            modules.game_hotkeys.addKeyCombo(weaponSkill1.hotkey, {autoSend = true, value = skill1, hasSpell = true})
            modules.game_hotkeys.save()
        end
        weaponSkill1.onClick = function() g_game.talk(info.words) end
    else
        weaponSkill1.onClick = nil
    end
    weaponSkill1.spell = skill1

    info = skill2 and WeaponInfo[skill2]
    weaponSkill2:setImageSource(info and info.icon or '/images/game/spelltree/spell_00')
    weaponSkill2:setTooltip(info and (skill2 .. '\n\n' .. info.description) or '')
    if info then
        if weaponSkill2.hotkey then
            modules.game_hotkeys.addKeyCombo(weaponSkill2.hotkey, {autoSend = true, value = skill2, hasSpell = true})
            modules.game_hotkeys.save()
        end
        weaponSkill2.onClick = function() g_game.talk(info.words) end
    else
        weaponSkill2.onClick = nil
    end
    weaponSkill2.spell = skill2
end

function init()
    connect(g_game, {
        onGameStart = onGameStart,
        onGameEnd   = onGameEnd
    })

    spellBarPanel = g_ui.loadUI('spellbar', modules.game_interface.getRootPanel())
    spellBarPanel:hide()

    weaponSkill1 = spellBarPanel:getChildById('weaponSkill1')
    weaponSkill2 = spellBarPanel:getChildById('weaponSkill2')

    spellBarBox = spellBarPanel:getChildById('spellBarBox')
    for i = 1, MAX_SLOTS do
        local slot = g_ui.createWidget('SpellWidget', spellBarBox)
        slot:setId('spell_' .. i)
    end

    ProtocolGame.registerExtendedOpcode(ExtendedIds.SpellCooldown, onUpdateSpellCooldown)

    g_mouse.bindPress(weaponSkill1, function() createHotkeyMenu(weaponSkill1) end, MouseRightButton)
    g_mouse.bindPress(weaponSkill2, function() createHotkeyMenu(weaponSkill2) end, MouseRightButton)

    if g_game.isOnline() then
        onGameStart()
    end
end

function terminate()
    disconnect(g_game, {
        onGameStart = onGameStart,
        onGameEnd   = onGameEnd
    })

    ProtocolGame.unregisterExtendedOpcode(ExtendedIds.SpellCooldown)

    spellBarPanel:destroy()
end

function onGameStart()
    spellBarPanel:show()
    sendUpdateSpellBar()
end

function onGameEnd()
    UIResetSpells()
    UIResetHotkey()

    spellBarPanel:hide()
end

-- Spellbar
function onUpdatePlayerSpells(protocol, code, buffer)
    if buffer == nil then
        return
    end

    UIResetSpells()

    local n = 0
    for i = 1, #buffer do
        local info = SpellInfo[buffer[i]]
        if info then
            n = n + 1
            local widget = spellBarBox:getChildById('spell_' .. n)
            if widget then
                widget:setIcon(info.icon)
                widget:setTooltip(buffer[i] .. '\n' .. info.description)

                widget.onClick = function() g_game.talk(info.words) end
                g_mouse.bindPress(widget, function() createHotkeyMenu(widget) end, MouseRightButton)

                widget.spell = buffer[i]
            end
        end
    end

    addEvent(modules.game_hotkeys.reload())
end

function UIResetSpells()
    spellBarBox:destroyChildren()
    for i = 1, MAX_SLOTS do
        local slot = g_ui.createWidget('SpellWidget', spellBarBox)
        slot:setId('spell_' .. i)
    end
end

function getSpellBarWidget(spell)
    for i = 1, MAX_SLOTS do
        local tmp = spellBarBox:getChildById('spell_' .. i)
        if tmp and tmp.spell and tmp.spell == spell then
            return tmp
        end
    end
    if weaponSkill1 and weaponSkill1.spell and weaponSkill1.spell == spell then
        return weaponSkill1
    elseif weaponSkill2 and weaponSkill2.spell and weaponSkill2.spell == spell then
        return weaponSkill2
    end
    return nil
end

-- Cooldown
function onUpdateSpellCooldown(protocol, code, buffer)
    local spell, duration = buffer[1], buffer[2]
    local widget = getSpellBarWidget(spell)
    if widget == nil then
        return
    end

    cooldown[spell] = {
        duration = duration * 1000,
        delay = duration * 1000,
        percent = 0
    }

    startCooldown(widget, spell)
end

function startCooldown(widget, spell)
    if widget == nil then return end
    local progressWidget = widget:getChildById('cooldown')
    if spell and cooldown[spell] then
        progressWidget:setPercent(cooldown[spell].percent or 0)

        progressWidget.callback = {}
        progressWidget.callback[CALLBACK_COOLDOWN_UPDATE] = function()
            updateCooldown(progressWidget, spell)
        end
        progressWidget.callback[CALLBACK_COOLDOWN_FINISH] = function()
            removeCooldown(progressWidget, spell)
        end

        progressWidget.callback[CALLBACK_COOLDOWN_UPDATE]()
    else
        removeCooldown(progressWidget)
    end
end

function removeCooldown(widget, spell)
    if widget.event then
        removeEvent(widget.event)
    end

    if cooldown[spell] then
        cooldown[spell] = nil
    end

    widget:setPercent(100)
    widget:setText('')
    widget.event = nil
end

function updateCooldown(widget, spell)
    local percent = widget:getPercent() + 10000 / cooldown[spell].duration
    widget:setPercent(percent)
    widget:setText(formatTime(cooldown[spell].delay / 1000))

    if widget:getPercent() < 100 then
        cooldown[spell].percent = percent
        cooldown[spell].delay = cooldown[spell].delay - 100

        if widget.event then
            removeEvent(widget.event)
        end

        widget.event = scheduleEvent(function()
            widget.callback[CALLBACK_COOLDOWN_UPDATE]()
        end, 100)
    else
        widget.callback[CALLBACK_COOLDOWN_FINISH]()
    end
end

-- Hotkeys
function getSpellBarWidgetByHotkey(keyCombo)
    for i = 1, MAX_SLOTS do
        local tmp = spellBarBox:getChildById('spell_' .. i)
        if tmp and tmp.hotkey and tmp.hotkey == keyCombo then
            return tmp
        end
    end
    if weaponSkill1 and weaponSkill1.hotkey and weaponSkill1.hotkey == hotkey then
        return weaponSkill1
    elseif weaponSkill2 and weaponSkill2.hotkey and weaponSkill2.spell == hotkey then
        return weaponSkill2
    end
    return nil
end

function setSpellBarHotkeyLabel(spell, text)
    local widget = getSpellBarWidget(spell)
    if widget ~= nil then
        widget:getChildById('hotkey'):setText(text or '')
        widget.hotkey = text
    end
end

function createHotkeyMenu(widget)
    local menu = g_ui.createWidget('PopupMenu')
    menu:addOption(tr('Set hotkey'), function() UISetHotkey(widget) end)
    if widget.hotkey then
        menu:addOption(tr('Remove hotkey'), function() UIRemoveHotkey(widget) end)
    else
        local option = menu:addOption(tr('Remove hotkey'), function() end)
        option:setEnabled(false)
    end
    menu:display()
end

function UISetHotkey(widget)
    local assignWindow = g_ui.createWidget('HotkeyAssignWindow', rootWidget)
    assignWindow:grabKeyboard()

    local assignLabel = assignWindow:getChildById('assignLabel')
    assignLabel:setText(tr('Please, press The key you wish to assign to this slot.'))
    assignWindow:getChildById('addButton'):setText(tr('Set'))
    assignWindow.spell = widget.spell
    assignWindow.widget = widget

    local comboLabel = assignWindow:getChildById('comboPreview')
    comboLabel.keyCombo = ''
    assignWindow.onKeyDown = hotkeyCapture
end

function UIRemoveHotkey(widget)
    modules.game_hotkeys.addKeyCombo(widget.hotkey)
    modules.game_hotkeys.save()

    widget:getChildById('hotkey'):setText('')
    widget.hotkey = nil
end

function UIResetHotkey()
    for i = 1, MAX_SLOTS do
        local tmp = spellBarBox:getChildById('spell_' .. i)
        if tmp and tmp.hotkey then
            tmp:getChildById('hotkey'):setText('')
            tmp.hotkey = nil
        end
    end
end

function hotkeyCapture(assignWindow, keyCode, keyboardModifiers)
    local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers)
    local comboPreview = assignWindow:getChildById('comboPreview')
    comboPreview:setText(tr('Current hotkey to add: %s', keyCombo))
    comboPreview.keyCombo = keyCombo
    comboPreview:resizeToText()
    assignWindow:getChildById('addButton'):enable()
    assignWindow:getChildById('addButton').onClick = function()
        hotkeyCaptureSet(assignWindow,comboPreview.keyCombo)
    end
    return true
end

function hotkeyCaptureSet(assignWindow, keyCombo)
    local widget = assignWindow.widget
    if widget and widget.hotkey then
        UIRemoveHotkey(assignWindow.widget)
    end

    local oldWidget = getSpellBarWidgetByHotkey(keyCombo)
    if oldWidget and widget ~= oldWidget then
        UIRemoveHotkey(oldWidget)
    end

    modules.game_hotkeys.addKeyCombo(keyCombo, {autoSend = true, value = assignWindow.spell, hasSpell = true})
    modules.game_hotkeys.save()

    assignWindow.widget.hotkey = keyCombo
    assignWindow:destroy()
end
