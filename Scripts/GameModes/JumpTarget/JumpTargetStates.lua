
--JUMPTARGETSTATES CLASS START
class 'JumpTargetStates'

function JumpTargetStates:__init()

	--These are the possible states for the players to be in
	--This player is currently playing
	self.PS_PLAY = 0
	--This player is being shown the winners list
	self.PS_SHOW_WINNERS = 1

	--These are the possible states for the game to be in
	--The server will wait for at least 1 person before starting the game
	self.GS_WAIT_FOR_PLAYERS = 0
	--This is the 3, 2, 1, GO! countdown before the round starts
	self.GS_COUNTDOWN = 1
	--This is where the players are actually playing
	self.GS_PLAY = 2
	--This is where the winners are shown to all players
	self.GS_SHOW_WINNERS = 3

end


function JumpTargetStates:GameStateToString(gameState)

	if gameState == self.GS_WAIT_FOR_PLAYERS then
		return "WAIT_FOR_PLAYERS"
	elseif gameState == self.GS_COUNTDOWN then
		return "COUNTDOWN"
	elseif gameState == self.GS_PLAY then
		return "PLAY"
	elseif gameState == self.GS_SHOW_WINNERS then
		return "SHOW_WINNERS"
	end

	error("Invalid game state " .. tostring(gameState) .. " passed into JumpTargetStates:GameStateToString()")

end


function JumpTargetStates:PlayerStateToString(playerState)

	if playerState == self.PS_PLAY then
		return "PLAY"
	elseif playerState == self.PS_WAIT_FOR_ROUND_END then
		return "WAIT_FOR_ROUND_END"
	elseif playerState == self.PS_SHOW_WINNERS then
		return "SHOW_WINNERS"
	end

	error("Invalid player state " .. tostring(playerState) .. " passed into JumpTargetStates:PlayerStateToString()")

end

--JUMPTARGETSTATES CLASS END