
Diary = {}

local Opcode = 247
local timeOn = 1*60*60 -- Tempo online. ( 3*60*60 equivale a 3 horas )

local diaryWindow
local diaryButton
local listDay
local lblTime
local lblDate

function Diary.init()

  connect(g_game, { 
    onGameStart = Diary.online,
    onGameEnd   = Diary.offline 
  })
  
  ProtocolGame.registerExtendedOpcode(Opcode, function(protocol, opcode, buffer)
    local actionAndResult = buffer:explode(">")
	if ( actionAndResult[1] == "daily" ) then
	  Diary.createListDay(actionAndResult[2]:explode("-"))    
	elseif ( actionAndResult[1] == "date" ) then	  
	  lblDate:setText(("%d / %d / %d"):format(actionAndResult[2], actionAndResult[3], actionAndResult[4]))
	  lblDate.date, lblDate.month, lblDate.year = tonumber(actionAndResult[2]), tonumber(actionAndResult[3]), tonumber(actionAndResult[4])
	end 
  end)
  
  diaryButton = modules.client_topmenu.addRightGameButton('diaryButton', tr('Daily Reward'), 'ui/daily', Diary.toggle)
  diaryWindow = g_ui.displayUI('diary')
      
  listDay = diaryWindow:getChildById('listDay')
  lblTime = diaryWindow:getChildById('lblTime')
  lblDate = diaryWindow:getChildById('lblDate')
end

function Diary.terminate()
  disconnect(g_game, { 
    onGameStart = Diary.online,
    onGameEnd   = Diary.offline 
  })
  ProtocolGame.unregisterExtendedOpcode(Opcode)
  diaryButton:destroy()
  diaryWindow:destroy()
end

function Diary.offline()
  removeEvent(lblTime.time)
  listDay:destroyChildren()
  diaryWindow:hide()
end

function Diary.online()
  Diary.initTime()
  lblTime.timeLeft = os.time()
  g_game.getProtocolGame():sendExtendedOpcode(Opcode, "send")
end

function Diary.initTime()
  local hours, minutes, seconds = 0, 0, 0
  lblTime.time = cycleEvent(function()
    seconds = seconds+1
    if ( seconds > 59 ) then seconds = 0   minutes = minutes+1 end
    if ( minutes > 59 ) then minutes = 0   hours   = hours+1   end
  lblTime:setText(string.format('%sh %sm %ss', hours, minutes, seconds))
  end, 1000)
end

function Diary.createListDay(value)
  listDay:destroyChildren()
  for i = 1, Date:getQtdDayOfMonth(lblDate.month, lblDate.year) do
    local uiDay = g_ui.createWidget('WidgetDay', listDay)
    uiDay:setId(i)
    uiDay:setText(i)
    if ( i < #value-1 ) then
      uiDay:setIcon('ui/'..value[i])
    end
  end
 
  local day   = lblDate.date
  local uiDay = listDay:getChildById(day)
  
  uiDay:setOn(true)
  
  if ( tonumber(value[day]) == 0 ) then
    uiDay.onClick = function(self)
      if ( os.time() - lblTime.timeLeft >= timeOn ) then
        self:setIcon('ui/1')    
        g_game.getProtocolGame():sendExtendedOpcode(Opcode, "get")
      else
        local timeLeft = Diary.timeString((lblTime.timeLeft+timeOn) - os.time())
        displayErrorBox('Daily Reward', "Faltam "..timeLeft.." para pegar sua recompensa!")
      end
    end
  else
    uiDay:setIcon('ui/1')
  end
end

function Diary.toggle()
  diaryWindow:setVisible(not diaryWindow:isVisible())
  g_game.getProtocolGame():sendExtendedOpcode(Opcode, "date")
end

function Diary.timeString(timeDiff)
  local dateFormat = {
  {"hora", timeDiff / 60 / 60 % 24},
  {"minuto", timeDiff / 60 % 60},
  {"segundo", timeDiff % 60}
  }
  
  local out = {}
  for k, t in ipairs(dateFormat) do
  local v = math.floor(t[2])
  if(v > 0) then
    table.insert(out, (k < #dateFormat and (#out > 0 and ', ' or '') or ' e ') .. v .. ' ' .. t[1] .. (v ~= 1 and 's' or ''))
  end
  end
  
  local ret = table.concat(out)
  if ret:len() < 16 and ret:find("segundo") then
  local a, b = ret:find(" e ")
  ret = ret:sub(b+1)
  end

  return ret
end
