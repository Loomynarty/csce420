/*
The following lines of code are facts that define which rooms are safe
and will not contain pits or wumpus.
*/
safe(1,1).
safe(1,2).
% safe(1,3).
% safe(1,4).
% safe(2,1).
safe(2,2).
% safe(2,3).
% safe(3,1).
% safe(3,3).
% safe(4,2).
% safe(4,3).
% safe(4,4).

% Define a predicate that checks if the given coordinates are valid and lie within the 4x4 grid.
val(X,Y):- X>0,X<5,Y>0,Y<5.

% The following two lines of code define the goal state that the agent
% is trying to reach. The agent will use BFS to find a path to this goal.

% Define the change in coordinates that the agent should make when it is trying to move forward in a certain direction.
move(0,0,1).
move(90,-1,0).
move(180,0,-1).
move(270,1,0).

% Define how the agent should turn when it changes direction.
% The first parameter is the current direction, the second parameter is
% the desired turn, and the third parameter is the new direction.
newdirection(0,'TurnRight',270).
newdirection(0,'TurnLeft',90).

newdirection(90,'TurnRight',0).
newdirection(90,'TurnLeft',180).

newdirection(180,'TurnRight',90).
newdirection(180,'TurnLeft',270).

newdirection(270,'TurnRight',180).
newdirection(270,'TurnLeft',0).

:- dynamic local_visited/3.
:- dynamic dst_X/1,dst_Y/1.

% retractall(local_visited(_, _,_)).

find_path(X,Y,Direction,Dst_X,Dst_Y,Actions):-
    safe(Dst_X,Dst_Y),
    safe(X,Y),
    format('Current Location :(~w,~w) and Direction:~w  Destination :(~w,~w)\n', [X, Y, Direction,Dst_X,Dst_Y]),
    retractall(dst_X(_)),
    retractall(dst_Y(_)),
    retractall(local_visited(_, _,_)),
    assert(dst_X(Dst_X)),
    assert(dst_Y(Dst_Y)),
    bfs([(X, Y, Direction, [])|[]], Actions).

% :- initialization retractall(local_visited(_, _,_)).

% queue is initially [(x, y, curr_direction, [])]
bfs([(X, Y, Direction, Path)|Queue], Actions) :-
    assert(local_visited(X, Y, Direction)),
    format('Current Location X:~w Y:~w Direction:~w \n', [X, Y, Direction]),

    (dst_X(X1),dst_Y(Y1), X =:= X1, Y =:= Y1 -> Actions = Path,write(Actions), !
    ;
        % Forward movement
        write('The agent is trying to move forward \n'),

        move(Direction,DX,DY),
        NewX is X + DX,
        NewY is Y + DY,

        (val(NewX, NewY),safe(NewX, NewY),\+ local_visited(NewX, NewY, Direction)->
        	write('The agent can move forward \n'),
        	assert(local_visited(NewX, NewY, Direction)),
        	format('NewX:~w NewY:~w Direction:~w \n', [NewX,NewY, Direction]),
        	append(Path, ['Forward'], NewPath),
        	append(Queue, [(NewX, NewY, Direction, NewPath)], NewQueue), !
            ;NewQueue = Queue),
        % Turn Left
        ( 	write('The agent is trying to move left\n'),
        	newdirection(Direction,'TurnLeft',NewDirection),\+ local_visited(X, Y, NewDirection) ->
        	write('The agent can move left\n'),
        	assert(local_visited(X, Y, NewDirection)),
        	format('X:~w Y:~w NewDirection:~w \n', [X,Y, NewDirection]),
        	append(Path, ['TurnLeft'], NewPath1),
        	% write(NewPath1),
        	append(NewQueue, [(X, Y, NewDirection, NewPath1)], NextQueue), !;
        	NextQueue=NewQueue
        ),
        ( 	write('The agent is trying to move right\n'),
        	newdirection(Direction,'TurnRight',NewDirection1),\+ local_visited(X, Y, NewDirection1),
        	write('The agent can move right\n'),
        	assert(local_visited(X, Y, NewDirection1)),
        	format('X:~w Y:~w NewDirection:~w \n', [X,Y, NewDirection1]),
        	append(Path, ['TurnRight'], NewPath2),
        	append(NextQueue, [(X, Y, NewDirection1, NewPath2)], FinalQueue), !;
        	FinalQueue=NextQueue
        ),
        write('Final Queue:'),
        write(FinalQueue),
        write('\n'),

 		bfs(FinalQueue, Actions)
    ).
