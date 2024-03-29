--GUIRACEPOSITION CLASS START

class 'GUIRacePosition' (IBase)

function GUIRacePosition:__init(initPlace, initPlaces, initLap, initLaps) super()
    self.posPrefix = "Position_"
	self.posGUILayout = GetMyGUISystem():LoadLayout("position.layout", self.posPrefix)
	self.posCont = self.posGUILayout:GetWidget(self.posPrefix .. "positioncont")
    self.placeImage = ToStaticImage(self.posCont:FindWidget(self.posPrefix .. "position"))
    self.placesText = self.posCont:FindWidget(self.posPrefix .. "positionstotal")

	self.lapCont = self.posGUILayout:GetWidget(self.posPrefix .. "lapcont")
    self.lapText = self.lapCont:FindWidget(self.posPrefix .. "lapcurrent")
    self.lapsText = self.lapCont:FindWidget(self.posPrefix .. "lapstotal")

	self.place = initPlace
	self.places = initPlaces
	self.lap = initLap
	self.laps = initLaps

	--Set the position and laps
	self:SetPlace(self.place)
	self:SetPlaces(self.places)
	self:SetLap(self.lap)
	self:SetLaps(self.laps)
end

function GUIRacePosition:BuildInterfaceDefIBase()

	self:AddClassDef("GUIRacePosition", "IBase", "The race position GUI manager")

end

function GUIRacePosition:InitIBase()

end


function GUIRacePosition:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.posGUILayout)
	self.posGUILayout = nil

end

function GUIRacePosition:SetVisible(visible)
    self.posCont:SetVisible(visible)
end

function GUIRacePosition:SetPlace(setPlace)

	if self.place ~= setPlace then
		self.place = setPlace

		self.placeImage:SetImageTexture("position_"..tostring(setPlace)..".png")
	end

end


function GUIRacePosition:SetPlaces(setPlaces)

	if self.places ~= setPlaces then
		self.places = setPlaces

		self.placesText:SetCaption(StringToUTFString(tostring(setPlaces)))
	end

end


function GUIRacePosition:SetLap(setLap)

	if self.lap ~= setLap then
		self.lap = setLap

		self.lapText:SetCaption(StringToUTFString(tostring(setLap)))
	end

end


function GUIRacePosition:SetLaps(setLaps)

	if self.laps ~= setLaps then
		self.laps = setLaps

		self.lapsText:SetCaption(StringToUTFString(tostring(setLaps)))
	end

end


function GUIRacePosition:SystemInited(initParams)
	self:SetPlace(self.place)
	self:SetPlaces(self.places)
	self:SetLap(self.lap)
	self:SetLaps(self.laps)
end

--GUIRACEPOSITION CLASS END