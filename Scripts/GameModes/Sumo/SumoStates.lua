
--SUMOSTATS CLASS START
class 'SumoStates'

function SumoStates:__init()

    --These are the possible states for the players to be in
	--The player joined the server and must wait for somebody else before the game starts
	self.PS_WAIT_FOR_PLAYERS = 0
	--This player is waiting for the game to begin after the countdown
	self.PS_COUNTDOWN = 1
	--This player is currently playing
	self.PS_PLAY = 2
	--This player has fallen out of the ring
	self.PS_FALLOUT = 3
	--This player is being shown the winners list
	self.PS_SHOW_WINNERS = 4
	--This player joined the game while a round had already started, they will wait for the next round
	self.PS_WAIT_FOR_ROUND_END = 5

	--These are the possible states for the game to be in
	self.GS_WAIT_FOR_PLAYERS = 0
	self.GS_PLAY = 1
	self.GS_COUNTDOWN = 2
	self.GS_SHOW_WINNERS = 3

	self.INIT_FUNC = 1
    self.UNINIT_FUNC = 2
    self.PROCESS_FUNC = 3

end


function SumoStates:InitStateFuncs(gameMode, stateFuncs)

    stateFuncs[self.GS_WAIT_FOR_PLAYERS] = { }
    stateFuncs[self.GS_WAIT_FOR_PLAYERS][self.INIT_FUNC] = gameMode.InitStateWaitForPlayers
    stateFuncs[self.GS_WAIT_FOR_PLAYERS][self.UNINIT_FUNC] = gameMode.UnInitStateWaitForPlayers
    stateFuncs[self.GS_WAIT_FOR_PLAYERS][self.PROCESS_FUNC] = gameMode.ProcessStateWaitForPlayers
    stateFuncs[self.GS_PLAY] = { }
    stateFuncs[self.GS_PLAY][self.INIT_FUNC] = gameMode.InitStatePlay
    stateFuncs[self.GS_PLAY][self.UNINIT_FUNC] = gameMode.UnInitStatePlay
    stateFuncs[self.GS_PLAY][self.PROCESS_FUNC] = gameMode.ProcessStatePlay
    stateFuncs[self.GS_COUNTDOWN] = { }
    stateFuncs[self.GS_COUNTDOWN][self.INIT_FUNC] = gameMode.InitStateCountdown
    stateFuncs[self.GS_COUNTDOWN][self.UNINIT_FUNC] = gameMode.UnInitStateCountdown
    stateFuncs[self.GS_COUNTDOWN][self.PROCESS_FUNC] = gameMode.ProcessStateCountdown
    stateFuncs[self.GS_SHOW_WINNERS] = { }
    stateFuncs[self.GS_SHOW_WINNERS][self.INIT_FUNC] = gameMode.InitStateShowWinners
    stateFuncs[self.GS_SHOW_WINNERS][self.UNINIT_FUNC] = gameMode.UnInitStateShowWinners
    stateFuncs[self.GS_SHOW_WINNERS][self.PROCESS_FUNC] = gameMode.ProcessStateShowWinners

end


function SumoStates:GameStateToString(gameState)

	if gameState == self.GS_WAIT_FOR_PLAYERS then
		return "WAIT_FOR_PLAYERS"
	elseif gameState == self.GS_PLAY then
		return "PLAY"
	elseif gameState == self.GS_COUNTDOWN then
		return "COUNTDOWN"
	elseif gameState == self.GS_SHOW_WINNERS then
		return "SHOW_WINNERS"
	end

	error("Invalid game state passed into SumoStates:GameStateToString()")

end


function SumoStates:PlayerStateToString(playerState)

	if playerState == self.PS_WAIT_FOR_PLAYERS then
		return "WAIT_FOR_PLAYERS"
	elseif playerState == self.PS_COUNTDOWN then
		return "COUNTDOWN"
	elseif playerState == self.PS_PLAY then
		return "PLAY"
	elseif playerState == self.PS_FALLOUT then
	    return "FALLOUT"
	elseif playerState == self.PS_SHOW_WINNERS then
		return "SHOW_WINNERS"
	elseif playerState == self.PS_WAIT_FOR_ROUND_END then
		return "WAIT_FOR_ROUND_END"
	end

	error("Invalid player state passed into SumoStates:PlayerStateToString()")

end