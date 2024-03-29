UseModule("ScriptModifier", "Scripts/Modifiers/")

--MATTRANSMODIFIER CLASS START

class 'MatTransModifier' (ScriptModifier)

function MatTransModifier:__init(transObject, startAlpha, endAlpha, overTime) super()

	self.transObject = transObject
	self.startAlpha = startAlpha
	self.endAlpha = endAlpha
	self.overTime = overTime
	self.clock = WTimer()

end


function MatTransModifier:__finalize()

end


function MatTransModifier:Process()

	--[[
	self.timePassed = self.timePassed + self.clock:GetTimeDifference()
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
	]]

end

--SCALEMODIFIER CLASS END