spellsWindow = nil
spellsButton = nil
spellsBox = nil
spellsBanner = nil

weaponSkill1 = nil
weaponSkill2 = nil

vocationCache = nil

local imgPath = {
    [1] = 'images/banner/fogo',
    [2] = 'images/banner/agua',
    [3] = 'images/banner/ar',
    [4] = 'images/banner/terra'
}

function sendUpdateSpellTree()
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(ExtendedIds.PlayerSpells)
    end
end

function getVocation()
    return vocationCache
end

function sendLearnSpellTree(pos, spell)
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(ExtendedIds.SpellTreeLearn, pos .. ";" .. spell)
    end
end

function learnConfirmBox(pos, spell, scroll_name, scroll_count)
    if learnWindow then
        return true
    end

    local learnFunc = function() sendLearnSpellTree(pos, spell) learnWindow:destroy() learnWindow = nil end
    local cancelFunc = function() learnWindow:destroy() learnWindow = nil end

    learnWindow = displayGeneralBox(spell, tr("To learn this spell you will need " .. scroll_count .. "x " .. scroll_name .. " Scrolls. Are you sure?"),
        {{ text=tr('Confirm'), callback=learnFunc }, { text=tr('Cancel'), callback = cancelFunc }, anchor = AnchorHorizontalCenter }, learnFunc, cancelFunc)

    return true
end

function init()
    connect(g_game, {
        onGameStart = updateSpellTree,
        onGameEnd   = offline
    })
    connect(LocalPlayer, {
        onLevelChange = onLevelChange,
    })

    spellsWindow = g_ui.displayUI('spells')
    spellsWindow:hide()

    g_keyboard.bindKeyDown('Ctrl+F', toggle)

    spellsButton = modules.client_topmenu.addRightGameToggleButton('spellsButton', tr('Spells') .. ' (Ctrl+F)', '/images/topbuttons/spelllist', toggle)
    spellsButton:setOn(false)

    spellsBox = spellsWindow:getChildById('spellsBox')
    spellsBanner = spellsWindow:getChildById('spellsBanner')

    weaponSkill1 = spellsWindow:getChildById('weaponSkill1')
    weaponSkill2 = spellsWindow:getChildById('weaponSkill2')

    ProtocolGame.registerExtendedOpcode(ExtendedIds.PlayerSpells, onUpdatePlayerSpells)
    ProtocolGame.registerExtendedOpcode(ExtendedIds.WeaponSpells, onUpdateWeaponSpells)

    updateWeaponSpells()
    if g_game.isOnline() then
        updateVocationImage(vocationCache)
        updateSpellTree()
    end
end

function terminate()
    disconnect(g_game, {
        onGameStart = updateSpellTree,
        onGameEnd   = offline
    })
    disconnect(LocalPlayer, {
        onLevelChange = onLevelChange,
    })

    g_keyboard.unbindKeyDown('Ctrl+F')

    ProtocolGame.unregisterExtendedOpcode(ExtendedIds.PlayerSpells)
    ProtocolGame.unregisterExtendedOpcode(ExtendedIds.WeaponSpells)

    spellsWindow:destroy()
    spellsButton:destroy()
end

function toggle()
    if spellsButton:isOn() then
        spellsButton:setOn(false)
        spellsWindow:hide()
    else
        spellsButton:setOn(true)
        spellsWindow:show()
        spellsWindow:raise()
        spellsWindow:focus()
        sendUpdateSpellTree()
    end
end

function onVocationChange(protocol, opcode, buffer)
    local voc = tonumber(buffer)
    vocationCache = voc
    updateVocationImage(voc)
    updateSpellTree()
end

function onUpdatePlayerSpells(protocol, opcode, buffer)
    -- ligar com a spellbar já que é a mesma lista de spells
    modules.game_spellbar.onUpdatePlayerSpells(protocol, opcode, buffer)

    for k, v in pairs(buffer) do
        local widget = spellsBox:recursiveGetChildById(v)
        if widget ~= nil then
            widget:setOn(true)
        end
    end
end

function onUpdateWeaponSpells(protocol, opcode, buffer)
    updateWeaponSpells(buffer[1], buffer[2])
    modules.game_spellbar.updateWeaponSpells(buffer[1], buffer[2])
end

function onLevelChange(localPlayer, value, percent)
    updateSpellTree()
end

function updateVocationImage(voc)
    spellsBanner:setImageSource(imgPath[voc])
end

function updateWeaponSpells(skill1, skill2)
    local info = skill1 and WeaponInfo[skill1]
    weaponSkill1:setImageSource(info and info.icon or '/images/game/spelltree/spell_00')
    weaponSkill1:setTooltip(info and (skill1 .. '\n\n' .. info.description) or '')

    info = skill2 and WeaponInfo[skill2]
    weaponSkill2:setImageSource(info and info.icon or '/images/game/spelltree/spell_00')
    weaponSkill2:setTooltip(info and (skill2 .. '\n\n' .. info.description) or '')
end

function updateSpellTree()
    local localPlayer = g_game.getLocalPlayer()
    if localPlayer == nil then return end
    local vocation = vocationCache

    if vocation == nil then return end

    local spells = SpellInfo
    local tree_config = SpellTree[vocation]

    spellsBox:emptyChildren()
    for i = 1, #tree_config do
        local horizontalWidget = g_ui.createWidget('WidgetHorizontalBox', spellsBox)

        local isScrollUnlocked = localPlayer:getLevel() >= tree_config[i].scroll_level

        local levelWidget = g_ui.createWidget('WidgetLevel', horizontalWidget)
        levelWidget:setOn(isScrollUnlocked)
        levelWidget:setText('' .. tree_config[i].scroll_level)
        levelWidget:setColor(isScrollUnlocked and '#40a72b' or '#b92020')
        levelWidget:setIcon('images/scrolls/' .. string.lower(tree_config[i].scroll_type))

        for k = 1, 3 do
            local spellName = tree_config[i].spells[k]
            if spellName == nil then break end
            local spellWidget = g_ui.createWidget('WidgetSpell', horizontalWidget)
            local spellData = spells[spellName]
            spellWidget:setEnabled(isScrollUnlocked)
            if spellData then
                spellWidget:setTooltip(spellData.description)
            end
            spellWidget:setId(spellName)
            spellWidget.onClick = function()
                if not spellWidget:isOn() then
                  learnConfirmBox(i, spellName, tree_config[i].scroll_type, tree_config[i].scroll_count)
                end
            end

            local label = spellWidget:getChildById('name')
            label:setText(spellName)

            if isScrollUnlocked then
                if spellData then
                    spellWidget:getChildById('spell'):setIcon(spellData.icon)
                end
            end
        end
    end
end

function offline()
    updateWeaponSpells()

    spellsBox:emptyChildren()

    spellsButton:setOn(false)
    spellsWindow:hide()

    vocationCache = nil
end
