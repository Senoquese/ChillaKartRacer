class 'PluginLoader' (IBase)

function PluginLoader:__init() super()
    self.plugins = { }
    self.pluginFile = "pluginScripts.txt"
    self:LoadPlugins()
end

function PluginLoader:LoadPlugins()
    local fname = self.pluginFile
    
    if IsValid(fname) then
        local file = io.open(fname, "r")
        
        if IsValid(file) then
            for line in file:lines() do
                if StartsWith(line, "#PLUGIN ") then
                    local strparams = WUtil_StringSplit(" ", line)
                    
                    if # strparams == 2 then
                        UseModule(strparams[2], ASSET_DIR .. "Scripts/Plugins/")
                        table.insert(self.plugins, _G[strparams[2]]())
                    end
                end
            end
            file:close()
        else
            print("PluginLoader: Error reading plugins file, creating new file")
            self:CreatePluginFile()
        end
    end
end

function PluginLoader:CreatePluginFile()
    local fname = self.pluginFile
    
    if IsValid(fname) then
        local file = io.open(fname, "w+")
        
        if IsValid(file) then
            file:write("This file contains scripts that will be loaded when the server/client starts. To add a new script,\n" ..
                       "Place it in the Scripts\Plugins directory, and add a new line to this file as follows:\n" ..
                       " #PLUGIN class_name (where class_name is the name of a class defined in the file)\n\n")
            
            file:flush()
            file:close()
        else
            error("PluginLoader: error creating plugin file")
        end
    end
end

function PluginLoader:BuildInterfaceDefIBase()
	self:AddClassDef("PluginLoader", "IBase", "Loads additional scripts from a file")
end

function PluginLoader:InitIBase()

end

function PluginLoader:UnInitIBase()

end