questLogButton = nil

function init()
  g_ui.importStyle('questlogwindow')

  questLogButton = modules.client_topmenu.addRightGameButton('questLogButton', tr('Quest Log'), '/images/topbuttons/questlog', function() g_game.requestQuestLog() end)
   
  connect(g_game, { 
	onQuestLog = onGameQuestLog,
	onQuestLine = onGameQuestLine,
	onGameEnd = destroyWindows
  })
end

function terminate()
  disconnect(g_game, { 
	onQuestLog = onGameQuestLog,
	onQuestLine = onGameQuestLine,
	onGameEnd = destroyWindows
  })
  
  destroyWindows()
  questLogButton:destroy()
end

function destroyWindows()
  if questLogWindow then
    questLogWindow:destroy()
  end
end

function onGameQuestLog(quests)
  destroyWindows()

  questLogWindow = g_ui.createWidget('QuestLogWindow', rootWidget)

  local cmbQuestList = questLogWindow:getChildById('cmbQuestList')
  local questList = questLogWindow:getChildById('questList')
  -- local missionDescription = questLogWindow:getChildById('missionDescription')
  
  cmbQuestList:addOption("» Quests «", -1)
  for i,questEntry in pairs(quests) do
    local id, name, completed = unpack(questEntry)
    cmbQuestList:addOption(name, id)
  end
  
  cmbQuestList.onOptionChange = function(combobox, text, data)
    if ( data == -1 ) then
	  questList:destroyChildren()
	  -- missionDescription:clearText()
	else
      g_game.requestQuestLine(data)
	end
  end  

  questLogWindow.onDestroy = function()
    questLogWindow = nil
  end
end

function onGameQuestLine(questId, questMissions)

  local questList = questLogWindow:getChildById('questList')
  -- local missionDescription = questLogWindow:getChildById('missionDescription')

  -- connect(questList, { 
    -- onChildFocusChange = function(self, focusedChild)
      -- if focusedChild == nil then return end
      -- missionDescription:setText(focusedChild.description)
    -- end 
  -- })

  questList:destroyChildren()
  for i,questMission in pairs(questMissions) do
    local name, description = unpack(questMission)
	local completed = name:find('OK')
	
    local missionLabel = g_ui.createWidget('MissionLabel')
    missionLabel:setText(name)
	missionLabel:setOn(completed)
	missionLabel:getChildById('chkMission'):setChecked(completed)
    missionLabel.description = description
    questList:addChild(missionLabel)
  end

  questList:focusChild(questList:getFirstChild())
end

