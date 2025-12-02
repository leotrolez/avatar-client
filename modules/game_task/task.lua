TaskWidget =
{
   Widgets =
   {
      windowButton = nil,
      window = nil,
      delayTaskWindow = nil,
      unlockRankWindow = nil
   },
   TaskButton = {}
}
TaskWidget.Ranks = {"D","C","B"}
TaskWidget.WidgetsButtons = {
   ["doneButtonWidget"] = "done",
   ["cancelButtonWidget"] = "cancel",
   ["acceptButtonWidget"] = "accept"
}
TaskWidget.ChangedFocus = false
TaskWidget.WindowID = "taskButton"
TaskWidget.Hotkey = "Ctrl + T"
TaskWidget.HasPlayerBuffer = false

TaskWidget.isInArray = function(array, value)
   for _, val in pairs(array) do
      if value == val then
         return true
      end
   end
   return false
end

function toggle()           
  if not g_game.getLocalPlayer() then
     return false
  end         
  if TaskWidget.Widgets.windowButton then        
     if TaskWidget.Widgets.windowButton:isOn() then
       TaskWidget.Widgets.window:hide()
       TaskWidget.Widgets.windowButton:setOn(false)
     else          
       local node = g_settings.getNode('firsttimeseta') or {}
       if node then
          if not node[TaskWidget.WindowID] then
             node[TaskWidget.WindowID] = true
             g_settings.setNode('firsttimeseta', node)
          end                
          if TaskWidget.Widgets.windowButton:getChildById('setaCima') then    
             TaskWidget.Widgets.windowButton:getChildById('setaCima'):destroy()
          end      
       end               
       TaskWidget.Widgets.window:show()
       TaskWidget.Widgets.windowButton:setOn(true)  
     end
  end
end

function onMiniWindowClose()    
   if TaskWidget.Widgets.delayTaskWindow then
      if TaskWidget.Widgets.delayTaskWindow.isOn then     
         TaskWidget.Widgets.delayTaskWindow.isOn = false
         TaskWidget.Widgets.delayTaskWindow:destroy()
         TaskWidget.Widgets.delayTaskWindow = nil
      end
   end
   if TaskWidget.Widgets.unlockRankWindow then    
      if TaskWidget.Widgets.unlockRankWindow.isOn then     
         TaskWidget.Widgets.unlockRankWindow.isOn = false
         TaskWidget.Widgets.unlockRankWindow:destroy()
         TaskWidget.Widgets.unlockRankWindow = nil
      end
   end    
end

function parseRank(rank)
   g_game.talk("!parseRank "..rank)
end    

ProtocolGame.registerExtendedOpcode(103,  
function (protocol, opcode, buffer)       
   if TaskWidget.Widgets.window then
      TaskWidget.Widgets.panelPTaskList = TaskWidget.Widgets.window:getChildById('panelPTask'):getChildById("panelPTaskList")   
      if buffer == "[resetList]" then
         for taskButton in pairs(TaskWidget.TaskButton) do 
            TaskWidget.TaskButton[taskButton]:destroy()
            TaskWidget.TaskButton[taskButton] = nil
         end
         return true
      end                          
      loadstring("__newBuffer = ".. buffer)()    
      if __newBuffer["[unlockRank]"] then 
         if not TaskWidget.Widgets.unlockRankWindow then
            TaskWidget.Widgets.unlockRankWindow = g_ui.createWidget('UnlockTaskWindow', rootWidget)  
            TaskWidget.Widgets.unlockRankWindow.isOn = true      
         end                                  
         TaskWidget.Widgets.unlockRankWindow:getChildById('unlockRankLevel'):setText("Level: "..__newBuffer["[unlockRank]"].level..".") 
         TaskWidget.Widgets.unlockRankWindow:getChildById('unlockRankPoints'):setText("Points: "..__newBuffer["[unlockRank]"].points..".")
         TaskWidget.Widgets.unlockRankWindow:getChildById('unlockRankRank'):setText("Unlocked: Rank "..__newBuffer["[unlockRank]"].rank..".")
         TaskWidget.Widgets.unlockRankWindow:getChildById('unlockRankUnlock').onClick = function()
            local p = 1
            for i=1, #TaskWidget.Ranks do           
               if TaskWidget.Ranks[i] == __newBuffer["[unlockRank]"].rank then
                  p = i
               end
            end           
            g_game.talk("!buyrank "..TaskWidget.Ranks[p+1])   
            onMiniWindowClose()      
         end 
         TaskWidget.HasPlayerBuffer = true
      end
      if __newBuffer["[delayTask]"] then  
         if not TaskWidget.Widgets.delayTaskWindow then
            TaskWidget.Widgets.delayTaskWindow = g_ui.createWidget('DelayTaskWindow', rootWidget)  
            TaskWidget.Widgets.delayTaskWindow.isOn = true     
         end                      
         TaskWidget.Widgets.delayTaskWindow:getChildById('minutesLabel'):setText("You need to wait "..__newBuffer["[delayTask]"].." minutes.")
         TaskWidget.HasPlayerBuffer = true                      
      end
      if __newBuffer["[pointsHave]"] then
         TaskWidget.Widgets.window:getChildById('labelPoints'):setText("Points: "..__newBuffer["[pointsHave]"])
         TaskWidget.HasPlayerBuffer = true
      end
      if __newBuffer["[unlockedRanks]"] then                  
         for i=1, #TaskWidget.Ranks do                            
            local taskRank = TaskWidget.Widgets.window:getChildById('PanelRanks'):getChildById("Rank"..TaskWidget.Ranks[i]):getChildById("RankButtonLock")
            if taskRank then
               if TaskWidget.isInArray(__newBuffer["[unlockedRanks]"], TaskWidget.Ranks[i]) then
                  taskRank:setImageSource("")
               else
                 -- taskRank:setImageSource("images/lock")
               end
            end
         end     
         TaskWidget.HasPlayerBuffer = true
      end      
      if TaskWidget.HasPlayerBuffer then
         TaskWidget.HasPlayerBuffer = false  
         return true
      end                                         
      for name, taskInfo in pairs(__newBuffer) do     
         local pass = false
         if TaskWidget.TaskButton[taskInfo.id] then
            pass = true
         end
         if not pass then                                        
            TaskWidget.TaskButton[taskInfo.id] = g_ui.createWidget('TaskButton', TaskWidget.Widgets.panelPTaskList)    
            TaskWidget.TaskButton[taskInfo.id].taskInfo = {doing = taskInfo.doing, kills = taskInfo.kills}
         end                                      
         local taskCreature = TaskWidget.TaskButton[taskInfo.id]:getChildById('CreatureUIPanel')   
         --- labels ---                   
         local labelKill = TaskWidget.TaskButton[taskInfo.id]:getChildById('labelKill')                       
         local labelLevel = TaskWidget.TaskButton[taskInfo.id]:getChildById('labelLevel')                      
         local labelReward = TaskWidget.TaskButton[taskInfo.id]:getChildById('labelReward')  
         --- hud (?) ---    
         local taskLevelHUD = TaskWidget.TaskButton[taskInfo.id]:getChildById('TaskLevel')                      
         local taskRewardHUD = TaskWidget.TaskButton[taskInfo.id]:getChildById('TaskReward')  
         ---------------     
         if TaskWidget.TaskButton[taskInfo.id].taskButtons then
            if TaskWidget.TaskButton[taskInfo.id].taskInfo.doing ~= taskInfo.doing then
               TaskWidget.TaskButton[taskInfo.id].taskButtons:destroy()
               TaskWidget.TaskButton[taskInfo.id].taskButtons = nil
            end
         end         
         if taskInfo.doing then                 
            taskLevelHUD:setImageClip(torect("0 0 159 13"))      
            taskRewardHUD:setImageClip(torect("159 0 63 13"))               
            TaskWidget.TaskButton[taskInfo.id]:setImageClip(torect("0 0 453 90"))       
            if not TaskWidget.TaskButton[taskInfo.id].taskButtons then
               TaskWidget.TaskButton[taskInfo.id].taskButtons = g_ui.createWidget('TaskDoneCancel', TaskWidget.TaskButton[taskInfo.id]) 
            end
         else                                           
            taskLevelHUD:setImageClip(torect("0 13 159 13"))      
            taskRewardHUD:setImageClip(torect("159 13 63 13"))    
            TaskWidget.TaskButton[taskInfo.id]:setImageClip(torect("0 90 453 90")) 
            if not TaskWidget.TaskButton[taskInfo.id].taskButtons then
               TaskWidget.TaskButton[taskInfo.id].taskButtons = g_ui.createWidget('TaskAccept', TaskWidget.TaskButton[taskInfo.id]) 
            end
         end    
         TaskWidget.TaskButton[taskInfo.id].taskInfo.doing = taskInfo.doing        
         for name, response in pairs(TaskWidget.WidgetsButtons) do  
            if TaskWidget.TaskButton[taskInfo.id].taskButtons then 
               if TaskWidget.TaskButton[taskInfo.id].taskButtons:getChildById(name) then  
                  TaskWidget.TaskButton[taskInfo.id].taskButtons:getChildById(name).id = taskInfo.id     
                  TaskWidget.TaskButton[taskInfo.id].taskButtons:getChildById(name).onClick = function()
                     g_game.talk("!task "..response..","..TaskWidget.TaskButton[taskInfo.id].taskButtons:getChildById(name).id)
                  end 
               end
            end
         end   
         if taskInfo.msg then
            local ribbonLabel = g_ui.createWidget('RibbonLabel', TaskWidget.TaskButton[taskInfo.id])
            ribbonLabel:setTooltip(tr(taskInfo.msg)) 
         end    
         if taskInfo.lookType then   
            for i=1,#taskInfo.lookType do
               local taskOutfit = g_ui.createWidget('TaskOutfit', taskCreature)
               taskOutfit:setOutfit({type=taskInfo.lookType[i]})
               taskOutfit:setTooltip("Task: "..taskInfo.id..".")
            end
            labelKill:setText(tostring(taskInfo.kills).."/"..tostring(taskInfo.count))
            labelLevel:setText(taskInfo.level)                                    
            labelReward:setText(taskInfo.reward)      
            taskCreature:setWidth(36*#taskInfo.lookType)    
         end
      end
   end
   return true
end
)      

function online()
   TaskWidget.Widgets.window = g_ui.createWidget('TaskWindow', rootWidget) 
   TaskWidget.Widgets.windowButton = modules.client_topmenu.addRightGameToggleButton(TaskWidget.WindowID, tr('Task') .. ' ('..TaskWidget.Hotkey..')', '/images/topbuttons/task', toggle, true, true)
   TaskWidget.Widgets.windowButton:setOn(false)
   TaskWidget.Widgets.window:hide()      
end

function offline()
   for widget in pairs(TaskWidget.Widgets) do
      if TaskWidget.Widgets[widget] ~= nil then
         TaskWidget.Widgets[widget]:destroy()
         TaskWidget.Widgets[widget] = nil
      end
   end
   return true
end

function init()
   g_ui.importStyle('task')    
   connect(g_game, { onGameStart = online, onGameEnd = offline })
   if g_game.getLocalPlayer() then
      online()
   end     
   g_keyboard.bindKeyDown(TaskWidget.Hotkey, toggle) 
end

function hide()
   if TaskWidget.Widgets.window then
      TaskWidget.Widgets.window:hide()
      TaskWidget.Widgets.windowButton:setOn(false) 
   end
end

function terminate()     
   ProtocolGame.unregisterExtendedOpcode(103)
   offline()        
end