arc(m, p, 8).
arc(q, p, 13).
arc(q, m, 5).
arc(k, q, 3).

% arc(a, g, 5).
% arc(b, d, 5).
% arc(c, d, 2).
% arc(d, e, 1).
% arc(d, f, 10).
% arc(e, b, 1).
% arc(e, f, 5).

path(A, B, P) :-
    % Get all paths from A -> B
    findall(P, find_path(A, B, P, [A]), L),

    % Sort paths by cost    
    keysort(L, Sorted),

    % Print the list out, newline for each path
    write("Paths Found (Cost-Path): \n"),
    print_paths(Sorted),
    write("\n"),
    
    % Access the first element from the sorted list, and unpair it
    nth0(0, Sorted, _-P),

    % Finish query
    !.

print_paths([H | []]) :- write(H). 
print_paths([H | T]) :- 
    write(H),
    write("\n"),
    print_paths(T).


% Find a path from A to B, "returning" a pair C-P
% C is the total cost of the path
% P is the path taken
find_path(A, B, C-[A, B], _) :- arc(A, B, C).
find_path(A, B, C-[A | P], V) :-
    arc(A, X, C1),

    % Prevent self selection
    A \== X, 

    % Check if already visited
    \+ member(X, V),

    find_path(X, B, C2-P, [X | V]),
    C is C1 + C2.