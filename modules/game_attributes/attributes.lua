AtributosPanel = nil
AtributosButton = nil

local atributos = {"health", "bend", "speed", "dodge"}
local cantClose = 0
local hasOpen = 0
local firstOpen = 1
canAddAtt = 1

local function hideTests()
  if firstOpen == 0 then
    if not g_game.isOnline() then
      if AtributosButton:isOn() then
        AtributosWindow:hide()
        AtributosButton:setOn(false)
      end
    elseif cantClose == 0 or hasOpen == 1 then
      AtributosWindow:show()
      AtributosButton:setOn(true)
      cantClose = 1
      hasOpen = 1
    end
  else
    firstOpen = 0
    cantClose = 1
  end
  scheduleEvent(function() hideTests() end, 500)
end

function init()
  canAddAtt = 1
  AtributosButton = modules.client_topmenu.addRightGameToggleButton('AtributosButton', tr('Atributos (Ctrl+E)'), '/images/topbuttons/atributos.png', toggle)
  AtributosButton:setOn(false)
  ProtocolGame.registerExtendedOpcode(38, onReceivePoint)
  ProtocolGame.registerExtendedOpcode(40, makeStates)
  ProtocolGame.registerExtendedOpcode(41, onReceivePendentes)

  AtributosWindow = g_ui.displayUI('attributes.otui')
  connect(g_game, { onGameStart = online,
  onReceivePoint = onReceivePoint,
  turnButtons = turnButtons,
  addAtribute = addAtribute,
  onGameEnd = destroyWindows})

  if not g_game.isOnline() then
    AtributosWindow:hide()
  end

  if AtributosButton:isOn() then
    AtributosWindow:hide()
    AtributosButton:setOn(false)
  else
    AtributosWindow:hide()
    AtributosButton:setOn(false)
  end
  cantClose = 0
  hasOpen = 0

  g_keyboard.bindKeyDown("Ctrl+E", toggle)
end

function turnButtons(type)
  for i = 1, #atributos do
    AtributosWindow:getChildById("Add"..atributos[i]..""):setEnabled(type == "on" and true or false)
  end
end

function onReceivePoint(protocol, opcode, buffer)
  buffer = string.explode(buffer, ",")
  local atributo = buffer[1]
  local novaQuantia = buffer[2]
  local novoCusto = buffer[3]
  local pontosPendentes = buffer[4]
  local strAtributo = "Value"..atributo..""
  local strCusto = "Cost"..atributo..""
  local QuantiaChild = AtributosWindow:getChildById(strAtributo)
  QuantiaChild:setText(novaQuantia)
  local CustoChild = AtributosWindow:getChildById(strCusto)
  CustoChild:setText(novoCusto)
  local PontosChild = AtributosWindow:getChildById("PontosPendentes")
  PontosChild:setText(pontosPendentes)
  if tonumber(pontosPendentes) > 0 then
    turnButtons("on")
    PontosChild:setColor("#32d968")
  else
    turnButtons("off")
    PontosChild:setColor("red")
  end
  return true
end

function onReceivePendentes(protocol, opcode, buffer)
  local pontosPendentes = tonumber(buffer)
  local PontosChild = AtributosWindow:getChildById("PontosPendentes")
  PontosChild:setText(pontosPendentes)
  if tonumber(pontosPendentes) > 0 then
    turnButtons("on")
    PontosChild:setColor("#32d968")
  else
    turnButtons("off")
    PontosChild:setColor("red")
  end
  return true
end

function makeStates(protocol, opcode, buffer)
  if buffer == nil or not buffer then return false end
  buffer = string.explode(buffer, ", ")
  local pontosPendentes = buffer[1]
  local PontosChild = AtributosWindow:getChildById("PontosPendentes")
  PontosChild:setText(pontosPendentes)
  if tonumber(pontosPendentes) > 0 then
    turnButtons("on")
    PontosChild:setColor("#32d968")
  else
    turnButtons("off")
    PontosChild:setColor("red")
  end
  for i = 1, (#buffer/2)-1 do
    fator = i*2
    valor = buffer[fator+1]
    custo = buffer[fator+2]
    atributo = atributos[i]
    strAtributo = "Value"..atributo..""
    strCusto = "Cost"..atributo..""
    local QuantiaChild = AtributosWindow:getChildById(strAtributo)
    local CustoChild = AtributosWindow:getChildById(strCusto)
    QuantiaChild:setText(valor)
    CustoChild:setText(custo)
  end
  return
end

function destroyWindows()
  AtributosWindow:hide()
  AtributosButton:setOn(false)
end

function terminate()
  disconnect(g_game, { onGameStart = online,
  onGameEnd = destroyWindows})

  AtributosButton:destroy()
  AtributosWindow:destroy()
end

function toggle()
  if AtributosButton:isOn() then
    AtributosButton:setOn(false)
    AtributosWindow:hide()
    hasOpen = 0
  else
    AtributosButton:setOn(true)
    AtributosWindow:show()
    AtributosWindow:raise()
    AtributosWindow:focus()
    hasOpen = 1
  end
end

function addAtribute(param, value, text)
  if canAddAtt == 0 then
    return false
  end
  canAddAtt = 0
  scheduleEvent(function() canAddAtt = 1 end, 300)
  return g_game.talkChannel(param, value, text)
end