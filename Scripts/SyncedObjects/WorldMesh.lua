UseModule("IBase", "Scripts/")

--WORLDMESH CLASS START

--WorldMesh
--BRIAN TODO: Make an IScriptObject
class 'WorldMesh' (IBase)

function WorldMesh:__init() super()

	self.name = "DefaultWorldMeshName"
	self.ID = 0
	self.initParams = Parameters()

	self.graphicalMesh = nil
	self.physicalMesh = nil

end


function WorldMesh:BuildInterfaceDefIBase()

	self:AddClassDef("WorldMesh", "IBase", "Defines a world mesh")

end


function WorldMesh:SetName(setName)

	self.name = setName

end


function WorldMesh:GetName()

	return self.name

end


function WorldMesh:SetID(setID)

	self.ID = setID

end


function WorldMesh:GetID()

	return self.ID

end


function WorldMesh:InitIBase()

	--Only the client has a graphical object
	if IsClient() then
		self:InitGraphical()
	end
	--Both the client and server simulate a physical object
	self:InitPhysical()

end


function WorldMesh:InitGraphical()

    local renderMeshParam = self.initParams:GetParameter("RenderMeshName", false)
    if renderMeshParam and string.len(renderMeshParam:GetStringData()) > 0 then
        self.graphicalMesh = OGREModel()
        self.graphicalMesh:SetName(self.name .. "G")
        self.graphicalMesh:Init(self.initParams)
    end

end


function WorldMesh:UnInitGraphical()

	if IsValid(self.graphicalMesh) then
		self.graphicalMesh:UnInit()
		self.graphicalMesh = nil
	end

end


function WorldMesh:InitPhysical()

	self.physicalMesh = BulletMesh()
	self.physicalMesh:SetName(self.name .. "P")
	self.physicalMesh:Init(self.initParams)

end


function WorldMesh:UnInitPhysical()

	if IsValid(self.physicalMesh) then
		self.physicalMesh:UnInit()
		self.physicalMesh = nil
	end

end


function WorldMesh:UnInitIBase()

	--Only the client has a graphical object
	if IsClient() then
		self:UnInitGraphical()
	end
	--Both the client and server simulate a physical object
	self:UnInitPhysical()

end


function WorldMesh:DoesOwn(ownObjectID)

	return false

end


function WorldMesh:Process(frameTime)

	if IsClient() and IsValid(self.graphicalMesh) then
		self.graphicalMesh:Process(frameTime)
	end
	self.physicalMesh:Process(frameTime)

end


function WorldMesh:SetParameter(param)

	self.initParams:AddParameter(Parameter(param))

end


function WorldMesh:EnumerateParameters(params)

	local i = 0
	while i < self.initParams:GetNumberOfParameters() do
		params:AddParameter(Parameter(self.initParams:GetParameter(i, true)))
		i = i + 1
	end

end


function WorldMesh:GetBoundingBox()

	if IsClient() and IsValid(self.graphicalMesh) then
		return self.graphicalMesh:GetBoundingBox()
	end
	return self.physicalMesh:GetBoundingBox()

end


function WorldMesh:NotifyPositionChange(setPos)

	if IsValid(self.physicalMesh) then
		self.physicalMesh:SetPosition(setPos)
	end
	if IsValid(self.graphicalMesh) then
		self.graphicalMesh:SetPosition(setPos)
	end

end


function WorldMesh:NotifyOrientationChange(setOrien)

	if IsValid(self.physicalMesh) then
		self.physicalMesh:SetOrientation(setOrien)
	end
	if IsValid(self.graphicalMesh) then
		self.graphicalMesh:SetOrientation(setOrien)
	end

end

--WORLDMESH CLASS END