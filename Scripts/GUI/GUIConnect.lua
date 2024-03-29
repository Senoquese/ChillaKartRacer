UseModule("IGUI", "Scripts/GUI/")

--GUICONNECT CLASS START

class 'GUIConnect' (IGUI)

function GUIConnect:__init() super()

	self.setPlayerNameSlot = self:CreateSlot("SetPlayerName", "SetPlayerName")
	self.connectToServerSlot = self:CreateSlot("ConnectToServer", "ConnectToServer")
	self.disconnectFromServerSlot = self:CreateSlot("DisconnectFromServer", "DisconnectFromServer")

	--The server connect dialog GUI
	local pageCreator = GUIPageCreator()
	pageCreator:SetPageName("ServerConnector")
	pageCreator:SetPageURL("local://Menu/connect.html")
	pageCreator:SetAbsoluteWidth(300)
	pageCreator:SetAbsoluteHeight(200)
	pageCreator:SetMovable(true)
	pageCreator:SetForceUpdates(true)
	self.networkGUI = GetNaviGUISystem():AddPage(pageCreator)
	self.networkGUI:RequestSlotConnectToSignal(self.setPlayerNameSlot, "SetPlayerName")
	self.networkGUI:RequestSlotConnectToSignal(self.connectToServerSlot, "ConnectToServer")
	self.networkGUI:RequestSlotConnectToSignal(self.disconnectFromServerSlot, "DisconnectFromServer")

	--Register this GUI with the IGUI base
	self:Set(self.networkGUI)

end


function GUIConnect:InitIGUI()

end


function GUIConnect:UnInitIGUI()

	GetNaviGUISystem():RemovePage(self.networkGUI:GetName())
	self.networkGUI = nil

end


--Set the player name from the GUI
function GUIConnect:SetPlayerName(guiParams)

	local playerName = guiParams:GetParameter("PlayerName", true):GetStringData()
	GetClientSystem():SetClientName(playerName)

end


--Connect to a server from a GUI
function GUIConnect:ConnectToServer(guiParams)

	--Query steam for the local player name
	if IsValid(GetSteamClientSystem) then
		local playerName = GetSteamClientSystem():GetLocalPlayerName()
		if string.len(playerName) > 0 then
			GetClientSystem():SetClientName(playerName)
		end
	end

	local serverAddress = guiParams:GetParameter("ServerAddress", true):GetStringData()
	GetClientSystem():RequestConnect(serverAddress, SavedItemsSerializer():GetSettingsAsParameters())

end


--Disconnect from a server from a GUI
function GUIConnect:DisconnectFromServer(guiParams)

	GetClientSystem():RequestDisconnect()

end

--GUICONNECT CLASS END