
function AssignInputMapping(networkedWorld)

	for inputName, inputVal in pairs(InputMap) do
        if IsClient() then
            networkedWorld:SetInputMapping(inputName, inputVal, GetClientInputManager():GetKeyCode(1, inputName),
                                           GetClientInputManager():GetKeyCode(2, inputName), InputSyncMap[inputName])
        else
            --Don't care about or have access to the key codes in the server, use 0
            networkedWorld:SetInputMapping(inputName, inputVal, 0, 0, InputSyncMap[inputName])
        end
	end

end


--InputMap is a global table to hold the input values for Zero Gear
InputMap = { }
InputMap.UseItemUp = 1
InputMap.UseItemDown = 2
InputMap.ControlAccel = 3
InputMap.ControlMouseLook = 4
InputMap.ControlReverse = 5
InputMap.ControlRight = 6
InputMap.ControlLeft = 7
InputMap.ControlReset = 8
InputMap.Hop = 9
InputMap.ControlBoost = 10
InputMap.ControlCameraLeft = 11
InputMap.ControlCameraRight = 12
InputMap.ControlCameraUp = 13
InputMap.ControlCameraDown = 14

--InputSyncMap indicates which input events should be synced across the network
InputSyncMap = { }
InputSyncMap.UseItemUp = true
InputSyncMap.UseItemDown = true
InputSyncMap.ControlAccel = true
InputSyncMap.ControlMouseLook = false
InputSyncMap.ControlReverse = true
InputSyncMap.ControlRight = true
InputSyncMap.ControlLeft = true
InputSyncMap.ControlReset = true
InputSyncMap.Hop = true
InputSyncMap.ControlBoost = true
InputSyncMap.ControlCameraLeft = false
InputSyncMap.ControlCameraRight = false
InputSyncMap.ControlCameraUp = false
InputSyncMap.ControlCameraDown = false