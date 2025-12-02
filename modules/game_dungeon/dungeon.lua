dungeonWindow = nil
dungeonsTabBar = nil

dungeons = {
  {name='Fire', image='fire.png'},
  {name='Water', image='water.png'},
  {name='Earth', image='earth.png'},
  {name='Air', image='air.png'},
}

function init()
  connect(g_game, { onGameEnd = onGameEnd })

  dungeonWindow = g_ui.loadUI('dungeon', modules.game_interface.getRootPanel())
  g_keyboard.bindKeyDown("Ctrl+U", toggle)

  dungeonTabBar = dungeonWindow:getChildById('dungeonTabBar')
  dungeonTabBar:setContentWidget(dungeonWindow:getChildById('dungeonTabContent'))

  for index, value in pairs(dungeons) do
    local panel = g_ui.loadUI('panel')
    dungeonTabBar:addTab(value.name, panel, '/images/dungeons/'..value.image)
  end
end

function terminate()
  disconnect(g_game, { onGameEnd = onGameEnd })
  g_keyboard.unbindKeyDown("Ctrl+U", toggle)
  dungeonWindow:destroy()
end

function onGameEnd()
  if dungeonWindow:isVisible() then
    dungeonWindow:hide()
  end
end

function show()
  dungeonWindow:show()
  dungeonWindow:raise()
  dungeonWindow:focus()
  addEvent(function() g_effects.fadeIn(dungeonWindow, 250) end)
end

function hide()
  addEvent(function() g_effects.fadeOut(dungeonWindow, 250) end)
  scheduleEvent(function() dungeonWindow:hide() end, 250)
end

function toggle()
  if dungeonWindow:isVisible() then
    hide()
  else
    show()
  end
end