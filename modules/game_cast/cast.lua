function init()
  
  castButton = modules.client_topmenu.addRightGameButton('castButton', tr('Gerenciar TV System'), '/images/topbuttons/cast', toggle, true)

  castSenha = g_ui.displayUI('castsenha')
  castKick = g_ui.displayUI('castkick')
  castBan = g_ui.displayUI('castban')
  castUnban = g_ui.displayUI('castunban')
  castMute = g_ui.displayUI('castmute')
  castUnmute = g_ui.displayUI('castunmute')

  g_keyboard.bindKeyDown('Escape', guildCancel)
end

function toggle()
  local menu = g_ui.createWidget('PopupMenu')
  menu:addOption(tr("Abrir a TV"), function() g_game.talk("/cast on") end)
  menu:addOption(tr("Fechar a TV"), function() g_game.talk("/cast off") end)
  menu:addSeparator()
  menu:addOption("Proteger a TV com Senha", function() castSenha:setVisible(true) end)
  menu:addOption(tr("Remover a Senha da TV"), function() g_game.talk("/cast password off") end)
  menu:addSeparator()
  menu:addOption("Expulsar Espectador da TV", function() castKick:setVisible(true) end)
  menu:addOption("Banir Espectador da TV", function() castBan:setVisible(true) end)
  menu:addSeparator()
  menu:addOption("Desbanir Espectador da TV", function() castUnban:setVisible(true) end)
  menu:addOption(tr("Espectadores Banidos da TV"), function() g_game.talk("/cast bans") end)
  menu:addSeparator()
  menu:addOption("Mutar Espectador da TV", function() castMute:setVisible(true) end)
  menu:addOption("Desmutar Espectador da TV", function() castUnmute:setVisible(true) end)
  menu:addSeparator()
  menu:addOption(tr("Espectadores Mutados da TV"), function() g_game.talk("/cast mutes") end)
  menu:addOption(tr("Qtd. de Espectadores Online na TV"), function() g_game.talk("/cast show") end)
  menu:addOption(tr("Status da TV"), function() g_game.talk("/cast status") end)
  menu:display()
end

function senhaCast()
  local text = castSenha:getChildById('senhaCastText'):getText()
  g_game.talk('/cast password ' .. text)
  castSenha:setVisible(false)
end

function kickCast()
  local text = castKick:getChildById('kickCastText'):getText()
  g_game.talk('/cast kick ' .. text)
  castKick:setVisible(false)
end

function banCast()
  local text = castBan:getChildById('banCastText'):getText()
  g_game.talk('/cast ban ' .. text)
  castBan:setVisible(false)
end

function unbanCast()
  local text = castUnban:getChildById('unbanCastText'):getText()
  g_game.talk('/cast unban ' .. text)
  castUnban:setVisible(false)
end

function muteCast()
  local text = castMute:getChildById('muteCastText'):getText()
  g_game.talk('/cast mute ' .. text)
  castMute:setVisible(false)
end

function unmuteCast()
  local text = castUnmute:getChildById('unmuteCastText'):getText()
  g_game.talk('/cast unmute ' .. text)
  castUnmute:setVisible(false)
end

function castCancel()
  castSenha:setVisible(false)
end
