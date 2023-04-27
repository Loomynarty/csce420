% my_agent.pl

%   this procedure requires the external definition of two procedures:
%
%     init_agent: called after new world is initialized.  should perform
%                 any needed agent initialization.
%
%     run_agent(percept,action): given the current percept, this procedure
%                 should return an appropriate action, which is then
%                 executed.
%
% This is what should be fleshed out

:- load_files([wumpus_world]).

:- dynamic haveArrow/0, goHome/0, wall/2, safe/2, shootWumpus/0, noBreeze/2, noStench/2, visited/2, stench/2, direction/1, boredom/1, gold/1, location/2.

% Define turns to always turn right for simplicity
turn(north, east).
turn(east, south).
turn(south, west).
turn(west, north).

update_fact(Old, New) :-
    retract(Old),
    assert(New).

% Initialize at the bottom left with an empty wallet and one arrow.
init_agent:-
  format('\n=====================================================\n'),
  format('This is init_agent:\n\tIt gets called once, use it for your initialization\n\n'),
  format('=====================================================\n\n'),

  % Retract all previous info
  retractall(haveArrow),
  retractall(goHome),
  retractall(wall(_, _)),
  retractall(safe(_, _)),
  retractall(shootWumpus),
  retractall(noBreeze(_, _)),
  retractall(noStench(_, _)),
  retractall(visited(_, _)),
  retractall(stench(_, _)),
  retractall(direction(_)),
  retractall(boredom(_)),
  retractall(gold(_)),
  retractall(location(_, _)),

  % Assert baseline stuff
	assert(haveArrow),
	assert(gold(0)),
	assert(location(1,1)),
	assert(visited(1,1)),
	assert(boredom(0)),
	assert(direction(east)).


% ------- run_agents -------
% run_agent(Percept, Action)
run_agent(_, _) :- 

  % Display the world
  display_world,

  % increment the boredom counter 
  boredom(X), 
  X1 is X + 1, 
  update_fact(boredom(X), boredom(X1)), 
  false().

% Return home if boredom has reached 15 or beyond
run_agent([_,_,_,_,_], _) :- 
  not(goHome), 
  boredom(X), 
  X >= 15, 
  assert(goHome), 
  write("I'm going home\n"), 
  false().

% Go back home if the agent has at least 1 gold and has shot the arrow
run_agent([_,_,_,_,_], _) :- 
  not(goHome), 
  gold(1), 
  not(haveArrow), 
  assert(goHome), 
  false().

% If scream is heard at any time, we know the wumpus is dead
run_agent([_,_,_,_,yes], _) :- 
  assert(shootWumpus), 
  false().

% Bumped into wall - retrace steps
run_agent([_,_,_,yes,_], turnright):- 
  location(X,Y), 
  retract(visited(X,Y)), 
  assert(wall(X,Y)),  
  get_next_location(X, Y, Dx, Dy), 
  DDx is (2 * X) - Dx, 
  DDy is (2 * Y) - Dy, 
  update_fact(location(X,Y), location(DDx, DDy)),
  write("bump\n"), 
  direction(A), 
  turn(A,B), 
  write("turn!"), 
  update_fact(direction(A), direction(B)).

% If there is a wumpus nearby, assert a stench
run_agent([yes,_,_,no,_], _):- 
  location(X,Y), 
  assert(stench(X, Y)), 
  write("I smell a Wumpus.\n"),
  false().

% If there is not a wumpus nearby, assert a noStench
run_agent([no,_,_,no,_], _):- 
  location(X,Y), 
  assert(noStench(X, Y)), 
  write("Smells fine.\n"), 
  false().

% If there is a pit nearby, assert nothing.
run_agent([_,yes,_,no,_], _):- 
  write("I feel a breeze.\n"), 
  false().

% If there is not a pit nearby, assert a noBreeze.
run_agent([_,no,_,no,_], _):- 
  location(X,Y), 
  assert(noBreeze(X, Y)), 
  write("The air is still.\n"), 
  false().

% Shoot the wumpus
run_agent([yes,_,_,_,_], shoot):- 
  haveArrow, 
  location(X,Y),
  get_next_location(X, Y, Dx, Dy), 
  conWumpus(Dx,Dy),
  write("The wumpus is in my sight!.\n"), 
  assert(safe(Dx, Dy)), 
  retract(haveArrow).

% Setup for arrow
run_agent(_, turnright):- 
  haveArrow, 
  location(X,Y), 
  wumpusFound(X,Y), 
  update_fact(boredom(_), boredom(0)), 
  direction(A), 
  turn(A,B), 
  update_fact(direction(A), direction(B)), 
  write("I found the wumpus!").

% Grab the gold
run_agent([_,_,yes,_,_], grab):- 
  gold(0), 
  write("grab\n"), 
  assert(gold(1)).

% Climb out if starting with a breeze
run_agent([_,yes,_,_,_], climb):- 
  location(1,1), 
  write("Not worth falling into a pit!\n") .

% Use arrow to determine the safe path
run_agent([yes,_,_,_,_], shoot):- 
  location(1,1), 
  haveArrow, 
  get_next_location(1, 1, Dx, Dy), 
  assert(safe(Dx, Dy)),
  retract(haveArrow), 
  write("I'm in a corner with the beast!.\n").

% Climb out if goHome
run_agent([_,_,_,_,_], climb):- 
  location(1,1), 
  goHome.

% If there could be a pit ahead, turn right.
run_agent([_,_,_,_,_], turnright):- 
  location(X,Y), 
  get_next_location(X, Y, Dx, Dy), 
  pit(Dx, Dy), 
  write("A pit is ahead.\n"),
  direction(A), 
  turn(A,B), 
  update_fact(direction(A), direction(B)).

% If there could be a live wumpus ahead, turn right.
run_agent([_,_,_,_,_], turnright):- 
  location(X,Y), 
  get_next_location(X, Y, Dx, Dy), 
  not(shootWumpus), 
  not(safe(Dx,Dy)),
  wumpus(Dx, Dy), 
  write("A wumpus is ahead.\n"), 
  direction(A),
  turn(A,B), 
  update_fact(direction(A), direction(B)).

% Avoid known walls
run_agent(_,turnright):- 
  location(X,Y), 
  get_next_location(X, Y, Dx, Dy), 
  wall(Dx, Dy), 
  direction(A), 
  turn(A,B),
  update_fact(direction(A), direction(B)), 
  write("Wall ahead.").

% Wander back home
run_agent(_, goforward):- 
  location(X,Y), 
  get_next_location(X, Y, Dx, Dy), 
  goHome, 
  visited(Dx,Dy),
  update_fact(location(X,Y), location(Dx, Dy)), 
  write("forward!").

% Wander to the gold
run_agent(_,turnleft):- 
  location(X,Y), 
  get_next_location(X, Y, Dx, Dy), 
  goHome, 
  not(visited(Dx, Dy)), 
  direction(A),
  turn(B,A), 
  update_fact(direction(A), direction(B)),
  write("Unvisited tile ahead, turn!").

run_agent(_,turnright):- 
  location(X,Y), 
  get_next_location(X, Y, Dx, Dy), 
  not(goHome), 
  unvisited(X, Y),
  update_fact(boredom(_), boredom(0)), 
  visited(Dx, Dy), 
  direction(A), 
  turn(A,B),
  update_fact(direction(A), direction(B)), 
  write("Unvisited tile nearby!").

% If nothing eventful happened, walk forward
run_agent(_,goforward):- 
  location(X,Y), 
  get_next_location(X, Y, Dx, Dy), 
  assert(visited(Dx, Dy)),
  update_fact(location(X,Y), location(Dx, Dy)), 
  write("forward!").



% ------- Helper Functions -------
% Get X and Y movement based on current direction
get_next_location(X, Y, Dx, Dy) :- direction(east), Dx is X + 1, Dy is Y.
get_next_location(X, Y, Dx, Dy) :- direction(north), Dx is X, Dy is Y + 1.
get_next_location(X, Y, Dx, Dy) :- direction(west), Dx is X - 1, Dy is Y.
get_next_location(X, Y, Dx, Dy) :- direction(south), Dx is X, Dy is Y - 1.

% Possible Wumpus?
% if none of the neighboring spaces lack a stench, we must assume a wumpus.
wumpus(X, Y) :- 
  not(visited(X, Y)), 
  X1 is X - 1, X2 is X + 1, 
  Y1 is Y - 1, Y2 is Y + 1,
  not(noStench(X1, Y)), 
  not(noStench(X2, Y)), 
  not(noStench(X, Y1)), 
  not(noStench(X, Y2)).

% wumpus nearby?
% Is one of neighboring tiles the wumpus?
% Tells the agent to look around to kill it.
wumpusFound(X, Y) :- X1 is X - 1, conWumpus(X1,Y).
wumpusFound(X, Y) :- X2 is X + 1, conWumpus(X2,Y).
wumpusFound(X, Y) :- Y1 is Y - 1, conWumpus(X,Y1).
wumpusFound(X, Y) :- Y2 is Y + 1, conWumpus(X,Y2).

% Confirmed Wumpus?
% If we found a tile with two neighboring stenches, we have likely found the wumpus and should kill it if we are looking at it.
conWumpus(X,Y) :- X1 is X - 1, Y1 is Y - 1, stench(X1, Y), stench(X, Y1), not(visited(X, Y)).
conWumpus(X,Y) :- X1 is X - 1, Y2 is Y + 1, stench(X1, Y), stench(X, Y2), not(visited(X, Y)).
conWumpus(X,Y) :- X1 is X - 1, X2 is X + 1, stench(X1, Y), stench(X2, Y), not(visited(X, Y)).
conWumpus(X,Y) :- X2 is X + 1, Y1 is Y - 1, stench(X2, Y), stench(X, Y1), not(visited(X, Y)).
conWumpus(X,Y) :- X2 is X + 1, Y2 is Y + 1, stench(X2, Y), stench(X, Y2), not(visited(X, Y)).
conWumpus(X,Y) :- Y1 is X + 1, Y2 is Y + 1, stench(X, Y1), stench(X, Y2), not(visited(X, Y)).

% Possible Pit?
% if none of the neighboring spaces lack a breeze, we must assume a wumpus.
pit(X, Y) :- 
  not(visited(X, Y)), 
  X1 is X - 1, X2 is X + 1, 
  Y1 is Y - 1, Y2 is Y + 1,
  not(noBreeze(X1, Y)), 
  not(noBreeze(X2, Y)), 
  not(noBreeze(X, Y1)), 
  not(noBreeze(X, Y2)).

% Is Safe?
% Is the tile safe? changes depending on the state of the wumpus and arrow.
isSafe(X,Y) :- not(pit(X,Y)), not(wumpus(X,Y)).
isSafe(X,Y) :- not(pit(X,Y)), shootWumpus.
isSafe(X,Y) :- not(pit(X,Y)), safe(X,Y).

% Unvisited nearby?
% Is one of neighboring tiles unvisited?
% We want to prioritize unvisited tiles.
unvisited(X, Y) :- X1 is X - 1, not(visited(X1, Y)), not(wall(X1,Y)), isSafe(X1,Y).
unvisited(X, Y) :- X2 is X + 1, not(visited(X2, Y)), not(wall(X2,Y)), isSafe(X2,Y).
unvisited(X, Y) :- Y1 is Y - 1, not(visited(X, Y1)), not(wall(X,Y1)), isSafe(X,Y1).
unvisited(X, Y) :- Y2 is Y + 1, not(visited(X, Y2)), not(wall(X,Y2)), isSafe(X,Y2).


