UseModule("IBase", "Scripts/Modifiers/")

--CAMERAMANAGER CLASS START

class 'CameraManager' (IBase)

function CameraManager:__init() super()

	self.followObjectChanged = self:CreateSignal("FollowObjectChanged")
	self.followObjectChangedParams = Parameters()

	self.cameraControllers = { }
	self.activeController = nil
	self.activeControllerPriority = -1

    self.cycleCameraEnabled = false
	self.currentCycleCamera = nil

	self.processEndSignal = self:CreateSignal("ProcessEnd")
	self.processParams = Parameters()

end


function CameraManager:BuildInterfaceDefIBase()

	self:AddClassDef("CameraManager", "IBase", "Manages all the camera controllers")

end


function CameraManager:InitIBase()

end


function CameraManager:UnInitIBase()

	self.cameraControllers = nil
	self.activeController = nil

end


function CameraManager:Process(frameTime)

    if self.cycleCameraEnabled == true then
        if IsValid(self.currentCycleCamera) then
            self.currentCycleCamera:Process(frameTime)
        end
    else
        if IsValid(self.activeController) then
            self.activeController:Process(frameTime)
        end
    end

	self.processEndSignal:Emit(self.processParams)

end


--The highest priority camera will be active
--A priority of 0 is the lowest, no two controllers can share the same priority
function CameraManager:AddController(controller, priority)

	if not IsValid(controller) then
		error("Invalid controller passed into CameraManager:AddController()")
	end

	local exists = self:GetControllerExists(controller)
	if exists then
		error("Passed in Camera Controller to AddController() already exists in CameraManager")
	end
	exists = self:GetControllerExists(priority)
	if exists then
		error("A Camera Controller with priority " .. tostring(priority) .. " already exists in CameraManager, AddController()")
	end

	table.insert(self.cameraControllers, { controller, priority })

	--If this new controller has a higher priority than the active controller, make it the active controller
	if priority > self.activeControllerPriority then
		self.activeController = controller
		self.activeControllerPriority = priority
		--Notify this controller it is now active
		self:_NotifyActive(self.activeController)
	end

end


function CameraManager:RemoveController(removeController)

	if not IsValid(removeController) then
		error("Invalid controller passed into CameraManager:RemoveController()")
	end

	for index, controller in ipairs(self.cameraControllers) do
		if controller[1] == removeController then
			--Check if this is the active controller
			if self.activeController == removeController then
				--Find the controller with the next lowest priority
				local nextLowestCon, nextLowestPri = self:_GetNextLowest(self.activeControllerPriority)
				self.activeController = nextLowestCon
				self.activeControllerPriority = nextLowestPri
				if IsValid(self.activeController) then
				    --Notify this controller it is now active
		            self:_NotifyActive(self.activeController)
				end
			end

			table.remove(self.cameraControllers, index)

			--Check if this is the cycle controller
			if self.currentCycleCamera == removeController then
			    self.currentCycleCamera = nil
			    --Cycle to the next valid camera
			    self:CycleCamera(self.cycleCameraEnabled)
			end

			break
		end
	end

end


function CameraManager:RemoveAllControllers()

	--First make a copy of the list so we can safely iterate over it
	local listCopy = { }
	for index, controller in ipairs(self.cameraControllers) do
		table.insert(listCopy, { controller[1], controller[2] })
	end

	--Remove each controller
	for index, controller in ipairs(listCopy) do
		self:RemoveController(controller[1])
	end
	listCopy = nil

end


--Returns true if the passed in camera is managed by the CameraManager
--Pass in the camera controller or a priority code
function CameraManager:GetControllerExists(controller)

	if not IsValid(controller) then
		error("Invalid controller passed into CameraManager:GetControllerExists()")
	end

	local checkPriority = false
	if type(controller) == "number" then
		checkPriority = true
	end
	for index, controller in ipairs(self.cameraControllers) do
		if checkPriority then
			if controller[1] == controller then
				return true
			end
		else
			if controller[2] == controller then
				return true
			end
		end
	end
	return false

end


function CameraManager:CycleCamera(enable)

    self.cycleCameraEnabled = enable

	if self.cycleCameraEnabled then
	    --If there is no cycle camera, use the first in the controller list
	    if self.currentCycleCamera == nil then
	        if #self.cameraControllers > 0 then
	            self.currentCycleCamera = self.cameraControllers[1][1]
	        end
	    else
	        --If there are no more camera controllers, set the current to nil
	        if #self.cameraControllers == 0 then
	            self.currentCycleCamera = nil
	        else
	            --Find the next camera to cycle to
                for index, controller in ipairs(self.cameraControllers) do
                    if controller[1] == self.currentCycleCamera then
                        if index ~= #self.cameraControllers then
                            self.currentCycleCamera = self.cameraControllers[index + 1][1]
                        else
                            self.currentCycleCamera = self.cameraControllers[1][1]
                        end
                        break
                    end
                end
            end
	    end
	    if IsValid(self.currentCycleCamera) then
			--Notify this controller it is now active
			self:_NotifyActive(self.currentCycleCamera)
        end
	end

end


function CameraManager:GetFollowObject()

	if IsValid(self.activeController) and IsValid(self.activeController.GetFollowObject) then
		return self.activeController:GetFollowObject()
	end
	return nil

end


function CameraManager:IsFollowObject(obj)

	return self:GetFollowObject() == obj

end


function CameraManager:_NotifyActive(newActiveController)

	newActiveController:NotifyActive()
	--Assume the follow object has changed
	self.followObjectChanged:Emit(self.followObjectChangedParams)

end


function CameraManager:_NotifyFollowObjectChanged(obj, camController)

	--If the follow object on the active controller has changed, emit the signal
	if IsValid(camController) and self.activeController == camController then
		self.followObjectChanged:Emit(self.followObjectChangedParams)
	end

end


function CameraManager:_GetNextLowest(priority)

	local nextLowest = { nil, priority }
	for index, controller in ipairs(self.cameraControllers) do
		--Lower than the current nextLowest?
		if controller[2] < nextLowest[2] then
			nextLowest = { controller[1], controller[2] }
		--Greater than the current nextLowest BUT greater than the passed in priority?
		elseif controller[2] > nextLowest[2] and controller[2] < priority then
			nextLowest = { controller[1], controller[2] }
		end
	end

	--Check if a nextLowest was found
	if nextLowest[1] == nil then
		--No next lowest, return default values
		nextLowest = { nil, -1 }
	end

	return nextLowest[1], nextLowest[2]

end

--CAMERAMANAGER CLASS END