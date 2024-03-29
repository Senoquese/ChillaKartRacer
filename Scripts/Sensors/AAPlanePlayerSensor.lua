
--AAPLANEPLAYERSENSOR CLASS START

--AAPlanePlayerSensor is an axis aligned plane sensor that senses only players
--An Axis Aligned Plane is defined with three values:
--An axis ("x", "y", or "z")
--A sign ("+" or "-")
--A value 5
--AAPlanePlayerSensor("y", "-", 5) would sense any object at or below -5 on the y axis
class 'AAPlanePlayerSensor' (IBase)

function AAPlanePlayerSensor:__init(setAxis, setSign, setValue) super()

	self.axis = setAxis
	self.setSign = setSign
	self.setValue = setValue

	--We are defining our own callback
	self.callbackSignal = self:CreateSignal("SensorCallback")
	self.callbackParams = Parameters()

end


function AAPlanePlayerSensor:BuildInterfaceDefIBase()

	self:AddClassDef("AAPlanePlayerSensor", "IBase", "An axis aligned plane sensor")

end


function AAPlanePlayerSensor:InitIBase()

end


function AAPlanePlayerSensor:UnInitIBase()

end


function AAPlanePlayerSensor:SetParameter(param)

	if param:GetName() == "Axis" then
		self.axis = param:GetStringData()
	elseif param:GetName() == "Sign" then
		self.sign = param:GetStringData()
	elseif param:GetName() == "Value" then
		self.value = param:GetFloatData()
	end

end


function AAPlanePlayerSensor:Process()

	--Iterate through all the players
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		local playerPos = player:GetPosition()
		local playerPosValue = 0

		--Find the player axis to test against
		if string.lower(self.axis) == "x" then
			playerPosValue = playerPos.x
		elseif string.lower(self.axis) == "y" then
			playerPosValue = playerPos.y
		else
			playerPosValue = playerPos.z
		end

        local withinRange = false
		--Test against the sensor value
		if self.sign == "+" then
			if playerPosValue > self.value or playerPosValue == self.value then
			    withinRange = true
			end
		else
			if playerPosValue < self.value or playerPosValue == self.value then
			    withinRange = true
			end
		end

		if withinRange then
		    --Player is within sensor range!
			self.callbackParams:GetOrCreateParameter("Player"):SetIntData(player:GetUniqueID())
			self.callbackParams:GetOrCreateParameter("Reason"):SetStringData("Plane")
			self.callbackSignal:Emit(self.callbackParams)
		end

		i = i + 1
	end

end


function AAPlanePlayerSensor:EnumerateParameters(params)

	params:AddParameter(Parameter("Axis", self.axis))
	params:AddParameter(Parameter("Sign", self.sign))
	params:AddParameter(Parameter("Value", self.value))

end


--This is the callback that will be called when an object is sensed
function AAPlanePlayerSensor:GetCallbackSignal()

	return self.callbackSignal

end

--AAPLANEPLAYERSENSOR CLASS END