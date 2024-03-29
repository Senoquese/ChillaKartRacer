
--RACESTATES CLASS START
class 'RaceStates'

function RaceStates:__init()

	--These are the possible states for the players to be in
	--The player joined the server and must wait for somebody else before the game starts
	self.PLAYER_STATE_WAIT_FOR_PLAYERS = 0
	--This player is waiting for the race to begin after the countdown
	self.PLAYER_STATE_COUNTDOWN = 1
	--This player is currently racing
	self.PLAYER_STATE_RACE = 2
	--This player is finished racing and is waiting for others to finish
	self.PLAYER_STATE_RACE_FINISHED = 3
	--This player is being shown the winners list
	self.PLAYER_STATE_SHOW_WINNERS = 4
	--This player joined the game while a race had already started, they will wait for the next race
	self.PLAYER_STATE_WAIT_FOR_RACE_END = 5

	--These are the possible states for the game to be in
	--The actual game doesn't start until at least 2 players are present
	self.GAME_STATE_WAIT_FOR_PLAYERS = 0
	--This is the 3, 2, 1, GO! countdown before the race starts
	self.GAME_STATE_COUNTDOWN = 1
	--This is where the players are actually racing
	self.GAME_STATE_RACE = 2
	--This is where the winners are shown to all players
	self.GAME_STATE_SHOW_WINNERS = 3

end


--Is the player in one of the racing states?
function RaceStates:IsPlayerRacing(playerState)

	if playerState == self.PLAYER_STATE_COUNTDOWN then
		return true
	elseif playerState == self.PLAYER_STATE_RACE then
		return true
	elseif playerState == self.PLAYER_STATE_RACE_FINISHED then
		return true
	elseif playerState == self.PLAYER_STATE_SHOW_WINNERS then
		return true
	end

	return false

end


function RaceStates:GameStateToString(gameState)

	if gameState == self.GAME_STATE_WAIT_FOR_PLAYERS then
		return "WAIT_FOR_PLAYERS"
	elseif gameState == self.GAME_STATE_COUNTDOWN then
		return "COUNTDOWN"
	elseif gameState == self.GAME_STATE_RACE then
		return "RACE"
	elseif gameState == self.GAME_STATE_SHOW_WINNERS then
		return "SHOW_WINNERS"
	end

	error("Invalid game state passed into RaceStates:GameStateToString()")

end


function RaceStates:PlayerStateToString(gameState)

	if gameState == self.PLAYER_STATE_WAIT_FOR_PLAYERS then
		return "WAIT_FOR_PLAYERS"
	elseif gameState == self.PLAYER_STATE_COUNTDOWN then
		return "COUNTDOWN"
	elseif gameState == self.PLAYER_STATE_RACE then
		return "RACE"
	elseif gameState == self.PLAYER_STATE_RACE_FINISHED then
		return "RACE_FINISHED"
	elseif gameState == self.PLAYER_STATE_SHOW_WINNERS then
		return "SHOW_WINNERS"
	elseif gameState == self.PLAYER_STATE_WAIT_FOR_RACE_END then
		return "WAIT_FOR_RACE_END"
	end

	error("Invalid game state passed into RaceStates:PlayerStateToString()")

end
--RACESTATES CLASS END