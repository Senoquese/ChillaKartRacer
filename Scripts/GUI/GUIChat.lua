--GUICHAT CLASS START

class 'GUIChat' (IBase)
UseModule("AchievementManager", "Scripts/")

--GetMyGUISystem():GetControllerManager():AddItem(self.chatView, ControllerFadeAlpha(0, 2, true))

function GUIChat:__init() super()

    self.achievements = AchievementManager()

	--We need to do some cleanup when the map unloads
	self.mapUnloadSlot = self:CreateSlot("MapUnloadSlot", "MapUnloadSlot")
	GetMapLoader():GetSignal("MapUnloadStart"):Connect(self.mapUnloadSlot)

	self.playerAddedSlot = self:CreateSlot("PlayerAdded", "PlayerAdded")
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.playerAddedSlot)
	self.playerAddedParams = Parameters()

	self.playerRemovedSlot = self:CreateSlot("PlayerRemoved", "PlayerRemoved")
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.playerRemovedSlot)
	self.playerRemovedParams = Parameters()

	self.startChatParams = Parameters()
	self.addPlayerMessageParams = Parameters()
	self.messageParams = Parameters()

    -- Chat color formatting
    self.chatColorSelf = "#00FF00"
    self.chatColorServer = "#FF0000"
    self.chatColorPlayer = "#FFFF00"
    self.chatColorTeamRed = "#FF0000"
    self.chatColorTeamBlue = "#4196FF"

    self.serverMsgPrefix = "_SM_"
    self.chatPrefix = "Chat_"
	self.chatGUILayout = GetMyGUISystem():LoadLayout("chat.layout", self.chatPrefix)
	--self.chatBg = self.chatGUILayout:GetWidget(self.chatPrefix .. "chatbg")
	self.chatInput = ToEdit(self.chatGUILayout:GetWidget(self.chatPrefix .. "chatinput"))
	self.chatView = ToEdit(self.chatGUILayout:GetWidget(self.chatPrefix .. "chatview"))

    --self.chatBg:SetAlpha(0)
	self.chatInput:SetAlpha(0)
	self.chatView:SetAlpha(0)

    self.fadeClock = WTimer()
    self.fadeClock:Reset()
    self.fadeClock:Stop()
    self.fadeTimeout = 10
    self.fadeOutDurationSeconds = 5
    self.fadeInDurationSeconds = 0.5

	--Receive message from the server
	self.receiveMessageSlot = self:CreateSlot("ReceiveChatMessage", "ReceiveChatMessage", GetClientSystem())
    self.processSlot = self:CreateSlot("Process", "Process")
    GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)
    self.keyPressedSlot = self:CreateSlot("KeyPressed", "KeyPressed")
	--We don't want focus to cause us to miss the return key in this case
	GetClientInputManager():GetSignal("KeyPressedIgnoreFocus", true):Connect(self.keyPressedSlot)

	--Send a message to the server
	self.sendMessageSignal = self:CreateSignal("SendChatMessage", GetClientSystem(), true)
	self.sendMessageParams = Parameters()

	self.startChat = false
	self.textEntryEnabled = false

end


function GUIChat:BuildInterfaceDefIBase()

	self:AddClassDef("GUIChat", "IBase", "The chat GUI manager")

end


function GUIChat:InitIBase()

end


function GUIChat:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.chatGUILayout)
	self.chatGUILayout = nil

end


function GUIChat:Process()

	if self.startChat then
		self.startChat = false
	end

    -- fade out chatView after timeout
    if self.fadeClock:GetTimeSeconds() >= self.fadeTimeout then
        self.fadeClock:Reset()
        self.fadeClock:Stop()
        GetMyGUISystem():GetControllerManager():RemoveItem(self.chatView)
        GetMyGUISystem():GetControllerManager():AddItem(self.chatView, ControllerFadeAlpha(0, 1/self.fadeOutDurationSeconds, true))
        --GetMyGUISystem():GetControllerManager():RemoveItem(self.chatBg)
        --GetMyGUISystem():GetControllerManager():AddItem(self.chatBg, ControllerFadeAlpha(0, 1/self.fadeOutDurationSeconds, true))
    end

end


--Called when the user wants to start typing into the chat box
function GUIChat:StartChat()

	--A delay prevents the start chat button from appearing in the chat text
	self.startChat = true
	self.textEntryEnabled = true
	GetMyGUISystem():GetInputManager():SetKeyFocusWidget(self.chatInput)
	GetMyGUISystem():GetControllerManager():RemoveItem(self.chatInput)
	self.chatInput:SetAlpha(1)
	self.chatGUILayout:SetVisible(true)
	
	GetMyGUISystem():GetControllerManager():RemoveItem(self.chatView)
    GetMyGUISystem():GetControllerManager():AddItem(self.chatView, ControllerFadeAlpha(1, 1/self.fadeInDurationSeconds, true))

end


--Called when the user wants to send the message
function GUIChat:SendMessage(overrideMessage)

    local message = overrideMessage
    if message == nil then
        local chatInputWidget = ToEdit(self.chatInput)
        chatInputWidget:SetTextSelection(0, chatInputWidget:GetTextLength())
        message = chatInputWidget:GetTextSelection():AsUTF8()
        local messageText = string.sub(message,8)
        chatInputWidget:DeleteTextSelection()

        self:CheckGGAchievement(messageText)

        print("Sending Message: " .. message .. " Text Length: " .. tostring(chatInputWidget:GetTextLength()))
    end

	if string.len(message) > 0 and IsValid(GetPlayerManager():GetLocalPlayer()) then
		local playerName = GetPlayerManager():GetLocalPlayer():GetName()

		self:AddMessage(self.chatColorSelf, playerName .. ": " .. message)

		--Send it to the server
		self.sendMessageParams:GetOrCreateParameter(0):SetStringData(playerName)
		self.sendMessageParams:GetOrCreateParameter(1):SetStringData(message)
		self.sendMessageSignal:Emit(self.sendMessageParams)
	end

    --Unfocus the chat
	GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
    GetMyGUISystem():GetControllerManager():AddItem(self.chatInput, ControllerFadeAlpha(0, 1/self.fadeInDurationSeconds, true))
	self.textEntryEnabled = false

end


--Called when we receive a chat message from the server
function GUIChat:ReceiveChatMessage(chatParams)

	local playerName = chatParams:GetParameterAtIndex(0, true):GetStringData()
	local message = chatParams:GetParameterAtIndex(1, true):GetStringData()
	local localPlayerName = GetPlayerManager():GetLocalPlayer():GetName()

    --Process special messages from the server
    if playerName == self.serverMsgPrefix then
        local prefixLen = self.serverMsgPrefix:len()
        if message:len() > prefixLen and message:sub(1, prefixLen) == self.serverMsgPrefix then
            self:AddMessage(self.chatColorServer, message:sub(prefixLen + 1))
        end
    
	--Only display messages that have data and are not from the local player
	elseif string.len(message) > 0 and playerName ~= localPlayerName then
		--local playerName = GetPlayerManager():GetLocalPlayer():GetName()
		self:AddMessage(self.chatColorPlayer, playerName .. ": " .. message)
	end

end


function GUIChat:PlayerAdded(playerParams)

	local playerID = playerParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	--BRIAN TODO: Localization
	self:AddMessage(self.chatColorServer, player:GetName() .. " joined the game")

end


function GUIChat:PlayerRemoved(playerParams)

	local playerID = playerParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	--BRIAN TODO: Localization
	self:AddMessage(self.chatColorServer, player:GetName() .. " left the game")

end


function GUIChat:AddMessage(messageRGB, messageStr)

	self.messageParams:GetOrCreateParameter(0):SetStringData(messageStr)
	self.messageParams:GetOrCreateParameter(1):SetStringData(messageRGB)	
	self.chatView:AddText(StringToUTFString(messageRGB .. messageStr .. "\n"))
    --self.chatView:AddText(StringToUTFString(messageStr .. "\n"))

    GetMyGUISystem():GetControllerManager():RemoveItem(self.chatView)
    GetMyGUISystem():GetControllerManager():AddItem(self.chatView, ControllerFadeAlpha(1, 1/self.fadeInDurationSeconds, true))
    --GetMyGUISystem():GetControllerManager():RemoveItem(self.chatBg)
    --GetMyGUISystem():GetControllerManager():AddItem(self.chatBg, ControllerFadeAlpha(1, 1/self.fadeInDurationSeconds, true))
    self.fadeClock:Reset()

end


function GUIChat:Clear()

	if IsValid(self.chatView) then
		self.chatView:SetTextSelection(0, self.chatView:GetTextLength())
		self.chatView:DeleteTextSelection()
		GetMyGUISystem():GetControllerManager():RemoveItem(self.chatView)
		self.chatView:SetAlpha(0)
		
		GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
        
	    self.textEntryEnabled = false
	end
	--if IsValid(self.chatBg) then
	--	GetMyGUISystem():GetControllerManager():RemoveItem(self.chatBg)
	--	self.chatBg:SetAlpha(0)
	--end

end


function GUIChat:MapUnloadSlot(mapParams)

    print("GUICHAT map unload start")

	--Simply clear the chat when the map unloads
	self:Clear()
	self.chatGUILayout:SetVisible(false)

	print("GUICHAT map unload finish")
	
end


function GUIChat:KeyPressed(keyParams)

	local key = keyParams:GetParameter("Key", true):GetIntData()

	if self.textEntryEnabled and (key == StringToKeyCode("RETURN") or key == StringToKeyCode("NUMENT")) then
	    self:SendMessage()
	end

end


function GUIChat:CheckGGAchievement(messageText)

    if string.upper(messageText) == "GG" then
	    local gm = GetClientManager():GetGameMode()
	    local resultsUp = false
	    --message = "gm: "..tostring(IsValid(gm))
	    if IsValid(gm.GetGameInResultsMode) then
	        resultsUp = gm:GetGameInResultsMode()
	    end
	    
	    if resultsUp then
	        self.achievements:Unlock(self.achievements.AVMT_GOOD_SPORT)
	    end
	end

end

--GUICHAT CLASS END