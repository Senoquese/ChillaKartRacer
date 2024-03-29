UseModule("ScriptModifier", "Scripts/Modifiers/")

--SCALEMODIFIER CLASS START

class 'ScaleModifier' (ScriptModifier)

function ScaleModifier:__init(scaleObject, endScale, overTime) super()

	self.scaleObject = scaleObject
	self.startScale = WVector3(scaleObject:GetScale())
	self.endScale = WVector3(endScale)
	self.overTime = overTime
	self.timePassed = 0

end


function ScaleModifier:__finalize()

end


function ScaleModifier:Process()

	self.timePassed = self.timePassed + GetFrameTime()
	local timePercent = self.timePassed / self.overTime
	if timePercent > 1 then
		timePercent = 1
	end

	local currentScale = WVector3()
	currentScale.x = Lerp(timePercent, self.startScale.x, self.endScale.x)
	currentScale.y = Lerp(timePercent, self.startScale.y, self.endScale.y)
	currentScale.z = Lerp(timePercent, self.startScale.z, self.endScale.z)
	self.scaleObject:SetScale(currentScale)

	if timePercent == 1 then
		self:EmitCallback()
	end

end

--SCALEMODIFIER CLASS END