
--REVERSETAGSTATE CLASS START
class 'ReverseTagStates'

function ReverseTagStates:__init()

	--These are the possible states for the players to be in
	--This player is IT
	self.PLAYER_STATE_IT = 0
	--This player is not IT
	self.PLAYER_STATE_NOT_IT = 1
	--This player is being shown the winners list
	self.PLAYER_STATE_SHOW_WINNERS = 2

	--These are the possible states for the game to be in
	--The actual game doesn't start until at least 1 player is present
	self.GAME_STATE_WAIT_FOR_PLAYERS = 0
	--The game is being played
	self.GAME_STATE_PLAY = 1
	--The game is being played with reversed rules
	self.GAME_STATE_PLAY_REVERSE = 2
	--This is where the winners are shown to all players
	self.GAME_STATE_SHOW_WINNERS = 3

end


--Is the player IT?
function ReverseTagStates:IsPlayerIT(playerState)

	if playerState == self.PLAYER_STATE_IT then
		return true
	end
	return false

end


function ReverseTagStates:GameStateToString(gameState)

	if gameState == self.GAME_STATE_WAIT_FOR_PLAYERS then
		return "WAIT_FOR_PLAYERS"
	elseif gameState == self.GAME_STATE_PLAY then
		return "PLAY"
	elseif gameState == self.GAME_STATE_PLAY_REVERSE then
		return "PLAY_REVERSE"
	elseif gameState == self.GAME_STATE_SHOW_WINNERS then
		return "SHOW_WINNERS"
	end

	error("Invalid game state passed into ReverseTagStates:GameStateToString()")

end


function ReverseTagStates:PlayerStateToString(gameState)

	if gameState == self.PLAYER_STATE_IT then
		return "IT"
	elseif gameState == self.PLAYER_STATE_NOT_IT then
		return "NOT_IT"
	elseif gameState == self.PLAYER_STATE_SHOW_WINNERS then
		return "SHOW_WINNERS"
	end

	error("Invalid game state passed into ReverseTagStates:PlayerStateToString()")

end

--REVERSETAGSTATES CLASS END