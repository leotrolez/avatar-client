function doRefleshClient()
    local protocolGame = g_game.getProtocolGame()

    if protocolGame then
        protocolGame:sendExtendedOpcode(2) --manda pro server, mandar todas spells
		protocolGame:sendExtendedOpcode(40)
		local outStr = "false"
		local markedOption = modules.client_options.getOption('autoloot')
		if markedOption then
			outStr = "true"
		end
		protocolGame:sendExtendedOpcode(131, outStr)
    end
end

function init()
    connect(g_game, {onGameStart = doRefleshClient})
end

function terminate()
    miniWindow:destroy()

    disconnect(g_game, {onGameStart = doRefleshClient})
end
