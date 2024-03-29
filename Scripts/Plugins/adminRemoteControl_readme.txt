AdminRemoteControl Documentation

The AdminRemoteControl plugin adds additional chat commands for server administrators to use to manage dedicated servers. There are also a few commands that can be used by all users.

PLUGIN INSTALLATION
1. Copy AdminRemoteControl.lua to the \Scripts\Plugins directory
2. In the Server directory, open the pluginScripts.txt file. (If the file does not exist, run a server and it will be created.)
3. Add the following line to the file: #PLUGIN AdminRemoteControl
4. Save the file.

PLUGIN CONFIGURATION
Run the server once after installing the plugin to automatically generate the basic configuration file, adminControlPermissions.txt.
Open the configuration file.
Permissions to grant access to the various commands are based on levels, which are just numbers from 0 and up.
Administrators are assigned permission levels from 1 and up. An administrator can only use commands whose permission level is greater than or equal to their own level. I.e., if a command has a permission level of 3, only an administrator of level 3, 2, or 1 can use that command.
A command with an access level of 0 means the command is disabled.

The configuration options are as follows:
#BANUNBANLEVEL <#>       - The permission level required to use the !ban and !unban commands.
#KICKLEVEL <#>           - The permission level required to use the !kick command.
#ADDREMOVEADMINLEVEL <#> - The permission level required to use the !addadmin and !removeadmin commands.
#PHYSICSLEVEL <#>        - The permission level required to use the !gravity command.
#MAPCHANGELEVEL <#>      - The permission level required to use the !changemap command.
#RESTARTLEVEL <#>        - The permission level required to use the !restart command.
#GETIDLEVEL <#>          - The permission level required to use the !getids command.

#ADMIN <steamID> <#>     - Denotes an administrator and their permission level. The first administrator will need to be added manually to this file.
                           The permission level must be greater than or equal to 1.

CHAT COMMANDS
(Notes: if a command parameter is listed "in quotes," it means the parameter must be enclosed in quotes if it is more than one word long.
Also, if a command requires a nickname as a parameter, you can just type the beginning of the nickname and the rest will be matched.)

nextmap  - Prints the next map in the server rotation. Any user can use this command.
timeleft - Prints how much time is left on the current map. Any user can use this command.

!kick <"nickname"|id> [reason]  - Kicks a user (by nickname or local ID) from the server with an optional reason.
!ban <"nickname"|id> [reason]   - Bans a user (by nickname or local ID) from the server with an optional reason.
!unban <nickname|steamID>       - Unbans a user (by nickname or steamID) from the server.
!changemap [mapname]            - Changes the map to whatever is requested. If no specific map is requested, the
                                  next map in the rotation will be loaded.
!restart                        - Restarts the race. (This command only works in race mode.)
!gravity [<x> <y> <z>]          - Modifies the world gravity. Leaving the parameter blank reverts to default gravity.
!getids                         - Lists the local IDs of players (for optional use with the !kick and !ban commands).
!addadmin <nickname> <level>    - Adds a new administrator with the specified access level, or modifies an administrator's access level.
                                  NOTE: You can only add/modify an administrator of a lower level than yourself, unless you have permission level 1.
!removeadmin <nickname|steamID> - Removes an administrator (by nickname, if they're on the server currently, or by steamID)
                                  NOTE: You can only remove an administrator of a lower level than yourself, unless you have permission level 1.
                                  (Yes, that means if you have permission level 1, you can remove yourself! Be careful!)

CONTACT
If you have any problems, suggestions, questions, or comments, e-mail cheetos1@gmail.com.