--GUINETWORKDISPLAY CLASS START

class 'GUINetworkDisplay' (IBase)

function GUINetworkDisplay:__init() super()

    self.netPrefix = "NetDisplay_"
	self.netGUILayout = GetMyGUISystem():LoadLayout("netinfo.layout", self.netPrefix)
	self.netCont = self.netGUILayout:GetWidget(self.netPrefix .. "container")

    self.clientFPS = self.netCont:FindWidget(self.netPrefix .. "fps")
    self.serverFPS = self.netCont:FindWidget(self.netPrefix .. "sfps")
    self.clientPing = self.netCont:FindWidget(self.netPrefix .. "ping")
    self.serverToClientSync = self.netCont:FindWidget(self.netPrefix .. "sync")
    self.inBytes = self.netCont:FindWidget(self.netPrefix .. "in")
    self.inKSec = self.netCont:FindWidget(self.netPrefix .. "insize")
    self.inPacketsSec = self.netCont:FindWidget(self.netPrefix .. "inpps") 
    self.outBytes = self.netCont:FindWidget(self.netPrefix .. "out")
    self.outKSec = self.netCont:FindWidget(self.netPrefix .. "outsize")
    self.outPacketsSec = self.netCont:FindWidget(self.netPrefix .. "outpps")
    self.lagTime = self.netCont:FindWidget(self.netPrefix .. "lagtime")

	self.updateClock = WTimer()
	self.updateTimer = 1 / 1

    self.processSlot = self:CreateSlot("Process", "Process")
    GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)

end

function GUINetworkDisplay:BuildInterfaceDefIBase()

	self:AddClassDef("GUINetworkDisplay", "IBase", "The Network Display GUI manager")

end


function GUINetworkDisplay:InitIBase()

end


function GUINetworkDisplay:UnInitIBase()

	GetMyGUISystem():UnloadLayout(self.netGUILayout)
	self.netGUILayout = nil

end


function GUINetworkDisplay:SetVisible(visible)

    self.netGUILayout:SetVisible(visible)

end


function GUINetworkDisplay:GetVisible()

    return self.netGUILayout:GetVisible()

end


function GUINetworkDisplay:Process()

	if self:GetVisible() and self.updateClock:GetTimeSeconds() > self.updateTimer and
       IsValid(GetClientSystem():GetServerPeer()) then

		self.updateClock:Reset()

		self.clientFPS:SetCaption(StringToUTFString(tostring( GetOGRESystem():GetFramerate() )))
		self.serverFPS:SetCaption(StringToUTFString(tostring( GetClientSystem():GetServerPeer():GetFramerate() )))
		self.clientPing:SetCaption(StringToUTFString(tostring( GetClientSystem():GetServerPing() * 1000 )))
		self.serverToClientSync:SetCaption(StringToUTFString(tostring( 1 / GetClientWorld():GetServerSyncMaxRate() )))
		self.inBytes:SetCaption(StringToUTFString(tostring( GetClientSystem():GetServerPeer():GetLastPacketReceivedSize() )))
		self.inKSec:SetCaption(StringToUTFString(tostring( GetClientSystem():GetServerPeer():GetIncomingBandwidthPerSecond() / 1024 )))
		self.inPacketsSec:SetCaption(StringToUTFString(tostring( GetClientSystem():GetServerPeer():GetNumberOfPacketsReceivedPerSecond() )))
		self.outBytes:SetCaption(StringToUTFString(tostring( GetClientSystem():GetServerPeer():GetLastPacketSentSize() )))
		self.outKSec:SetCaption(StringToUTFString(tostring( GetClientSystem():GetServerPeer():GetOutgoingBandwidthPerSecond() / 1024 )))
		self.outPacketsSec:SetCaption(StringToUTFString(tostring( GetClientSystem():GetServerPeer():GetNumberOfPacketsSentPerSecond() )))
		self.lagTime:SetCaption(StringToUTFString(tostring(GetClientWorld():GetWorldViewLagTime())))
	end

end

--GUINETWORKDISPLAY CLASS END