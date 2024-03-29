--BRIAN TODO: Not used, can get rid of?

UseModule("IBase", "Scripts/")

--COLLISIONEVENT CLASS DEFINITION START

class 'CollisionEvent' (IBase)

function CollisionEvent:__init(setBodyAName, setBodyBName) super()

	self:Start(setBodyAName, setBodyBName)

end


function CollisionEvent:Start(setBodyAName, setBodyBName)

	self.bodyAName = setBodyAName
	self.bodyBName = setBodyBName
	self.startTime = GetTime()
	--This flag keeps track of if this collision has ended
	self.hasCollisionEnded = false

end


--This collision happened again with these two bodies, restart the event
function CollisionEvent:Restart()

	self:Start(self.bodyAName, self.bodyBName)

end


function CollisionEvent:GetBodyAName()

	return self.bodyAName

end


function CollisionEvent:GetBodyBName()

	return self.bodyBName

end


function CollisionEvent:GetStartTime()

	return self.startTime

end


function CollisionEvent:HasEnded()

	return self.hasCollisionEnded

end


function CollisionEvent:SetEnded(setEnded)

	self.hasCollisionEnded = setEnded

end


function CollisionEvent:ContainsBodies(containBodyAName, containBodyBName)

	if (self.bodyAName == containBodyAName and self.bodyBName == containBodyBName) or
	   (self.bodyBName == containBodyAName and self.bodyAName == containBodyBName) then
		return true
	end

	return false

end

--COLLISIONEVENT CLASS DEFINITION END


--COLLISIONEVENTMANAGER CLASS DEFINITION START

--The CollisionEventManager will maintain a list of recent collisions and
--return information about them
class 'CollisionEventManager'

function CollisionEventManager:__init()

	self.collisionEvents = { }
	self.clearCollisionTimer = 5

end


function CollisionEventManager:AddEvent(addEvent)

	local event = self:GetEvent(addEvent:GetBodyAName(), addEvent:GetBodyBName())
	if event ~= nil then
		--This collision is happening again, restart it
		event:Restart()
	else
		--New event, add it to our list
		table.insert(self.collisionEvents, addEvent)
	end

end


function CollisionEventManager:GetEvent(forBodyAName, forBodyBName)

	for index, event in ipairs(self.collisionEvents)
	do
		if event:ContainsBodies(forBodyAName, forBodyBName) then
			return event
		end
	end

	--Not found
	return nil

end


function CollisionEventManager:GetCollisionStartTime(forBodyAName, forBodyBName)

	local event = self:GetEvent(forBodyAName, forBodyBName)
	if event ~= nil then
		return event:GetStartTime()
	end

	--No collision registered for these bodies
	return 0

end


--Check if any of the events are too old, if so, remove them
function CollisionEventManager:Process()

	local currentTime = GetTime()
	for index, event in ipairs(self.collisionEvents)
	do
		--self.clearCollisionTimer is the threshold to clear out an old collision
		if currentTime - event:GetStartTime() > self.clearCollisionTimer then
			--Is this safe to do???
			table.remove(self.collisionEvents, index)
		end
	end

end

--COLLISIONEVENTMANAGER CLASS DEFINITION END