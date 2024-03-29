
--JUMPTARGETSTATES CLASS START
class 'FreeStates'

function FreeStates:__init()

	--These are the possible states for the game to be in
	self.GS_WAIT_FOR_PLAYERS = 0
	self.GS_PLAY = 1
	self.GS_COUNTDOWN = 2
	self.GS_SHOW_WINNERS = 3

end