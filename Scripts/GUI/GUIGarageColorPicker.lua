
--GUIGARAGECOLORPICKER CLASS START

class 'GUIGarageColorPicker' (IBase)

function GUIGarageColorPicker:__init() super()

	self.colorPickSignal = self:CreateSignal("ColorPick")
	self.closePickerSignal = self:CreateSignal("ClosePicker")

end


function GUIGarageColorPicker:BuildInterfaceDefIBase()

	self:AddClassDef("GUIGarageColorPicker", "IBase", "The Garage Color Picker GUI manager")

end


function GUIGarageColorPicker:InitGUISignalsAndSlots()

	self.colorPickSlot = self:CreateSlot("colorPick", "ColorPick")
	self.guiColorPicker:GetSignal("ColorChange", true):Connect(self.colorPickSlot)

	self.closeColorPickerSlot = self:CreateSlot("closeColorPicker", "CloseColorPicker")
	self.guiColorPicker:GetSignal("ColorAccept", true):Connect(self.closeColorPickerSlot)
	
	self.colorIndexChangeSlot = self:CreateSlot("ColorIndexChange","ColorIndexChange")
    self.guiColorPicker:GetSignal("ColorIndexChange", true):Connect(self.colorIndexChangeSlot)

end


function GUIGarageColorPicker:InitIBase()

	self.guiColorPicker = MyGUIColorPicker()

	self.guiColorPicker:SetIndexActive(0)

	self:InitGUISignalsAndSlots()

end


function GUIGarageColorPicker:UnInitIBase()

	if IsValid(self.guiColorPicker) then
		self.guiColorPicker:UnInit()
	end
	self.guiColorPicker = nil

end


function GUIGarageColorPicker:SetVisible(visible)

	if IsValid(self.guiColorPicker) then
		self.guiColorPicker:SetVisible(visible)
	end

end


function GUIGarageColorPicker:GetVisible()

	if IsValid(self.guiColorPicker) then
		self.guiColorPicker:GetVisible()
	end

end

function GUIGarageColorPicker:ColorIndexChange(bucketParams)

    --print("ColorIndexChange")
    if IsValid(self.lastBucket) then
        local newIndex = bucketParams:GetParameter("Index", true):GetIntData()
        if newIndex ~= self.lastBucket then
	        GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Paint_"..math.modf((Random() * 3) + 1)..".wav", WVector3(),1.0, 10, false, SoundSystem.MEDIUM)
	        self.lastBucket = newIndex
	    end
	else
	    self.lastBucket = 0
	end

end

function GUIGarageColorPicker:SetActiveBucket(index)
    self.guiColorPicker:SetIndexActive(index)
end

function GUIGarageColorPicker:SetBucketCount(numBuckets)
    
    print("GUIGarageColorPicker:SetBucketCount:"..numBuckets)
    self.guiColorPicker:SetIndexVisible(0, 0 < numBuckets)
	self.guiColorPicker:SetIndexVisible(1, 1 < numBuckets)
	self.guiColorPicker:SetIndexVisible(2, 2 < numBuckets)
	self.guiColorPicker:SetIndexVisible(3, 3 < numBuckets)
	
	self.guiColorPicker:SetIndexActive(0)
	
	self:SetVisible(numBuckets > 0)
	
end

function GUIGarageColorPicker:SetBucketColor(bucket, colorStr)

    print("GUIGarageColorPicker:SetBucketColor: - "..bucket..": "..colorStr)
    local ct = WUtil_StringSplit(" %s*", colorStr)
    local r = tonumber(ct[1])
    local g = tonumber(ct[2])
    local b = tonumber(ct[3])
    self.guiColorPicker:SetColor(WColorValue(r, g, b, 0), bucket)

end

function GUIGarageColorPicker:ColorPick(colorParams)

	--Convert colors from 0 - 255 to 0 - 1?
	local red = colorParams:GetParameter("Red", true):GetFloatData()
	local green = colorParams:GetParameter("Green", true):GetFloatData()
	local blue = colorParams:GetParameter("Blue", true):GetFloatData()
	local colorBucketIndex = colorParams:GetParameter("Index", true):GetIntData()

	colorParams:GetParameter(0, true):SetFloatData(red)
	colorParams:GetParameter(1, true):SetFloatData(green)
	colorParams:GetParameter(2, true):SetFloatData(blue)
	colorParams:GetParameter(3, true):SetIntData(colorBucketIndex)

	print("GUIGarageColorPicker:ColorPick - "..colorBucketIndex..": "..red.." "..green.." "..blue)

	self.colorPickSignal:Emit(colorParams)

end


function GUIGarageColorPicker:CloseColorPicker(closeParams)

	self.closePickerSignal:Emit(closeParams)

end

--GUIGARAGECOLORPICKER CLASS END