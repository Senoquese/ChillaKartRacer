
function Help()

	GetConsole():Print("ListObjects() - List all of the objects currently in the system");

end


function ListObjects()

	GetObjectSystem():ListObjects()

end


function ToggleDebugShadows()

	EnableDebugShadows(not DebugShadowsEnabled())

end