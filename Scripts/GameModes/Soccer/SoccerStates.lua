
--SOCCERSTATES CLASS START
class 'SoccerStates'

function SoccerStates:__init()

	--These are the possible states for the players to be in
	--This player is playing
	self.PS_PLAYING = 0
	--This player is not playing (waiting for the game to start after a goal was scored)
	self.PS_NOT_PLAYING = 1
	--This player is being shown the winners list
	self.PS_SHOW_WINNERS = 2

	--These are the possible states for the game to be in
	--The actual game doesn't start until at least 1 player is present
	self.GS_WAIT_FOR_PLAYERS = 0
	--The game is about to start
	self.GS_COUNTDOWN = 1
	--The game is being played
	self.GS_PLAY = 2
	--A goal was just scored
	self.GS_GOAL_SCORED = 3
	--This is where the winners are shown to all players
	self.GS_SHOW_WINNERS = 4

end


function SoccerStates:GameStateToString(gameState)

	if gameState == self.GS_WAIT_FOR_PLAYERS then
		return "WAIT_FOR_PLAYERS"
	elseif gameState == self.GS_COUNTDOWN then
		return "COUNTDOWN"
	elseif gameState == self.GS_PLAY then
		return "PLAY"
	elseif gameState == self.GS_GOAL_SCORED then
		return "GOAL_SCORED"
	elseif gameState == self.GS_SHOW_WINNERS then
		return "SHOW_WINNERS"
	end

	error("Invalid game state passed into SoccerStates:GameStateToString()")

end


function SoccerStates:PlayerStateToString(playerState)

	if playerState == self.PS_PLAYING then
		return "PLAYING"
	elseif playerState == self.PS_NOT_PLAYING then
		return "NOT_PLAYING"
	elseif playerState == self.PS_SHOW_WINNERS then
		return "SHOW_WINNERS"
	end

	error("Invalid player state passed into SoccerStates:PlayerStateToString()")

end

--SOCCERSTATES CLASS END