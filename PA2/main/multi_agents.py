from __future__ import print_function

# multi_agents.py
# --------------
# Licensing Information:  You are free to use or extend these projects for
# educational purposes provided that (1) you do not distribute or publish
# solutions, (2) you retain this notice, and (3) you provide clear
# attribution to UC Berkeley, including a link to http://ai.berkeley.edu.
# 
# Attribution Information: The Pacman AI projects were developed at UC Berkeley.
# The core projects and autograders were primarily created by John DeNero
# (denero@cs.berkeley.edu) and Dan Klein (klein@cs.berkeley.edu).
# Student side autograding was added by Brad Miller, Nick Hay, and
# Pieter Abbeel (pabbeel@cs.berkeley.edu).


from builtins import range
from util import manhattan_distance
from game import Directions
import random, util

from game import Agent

class ReflexAgent(Agent):
    """
      A reflex agent chooses an action at each choice point by examining
      its alternatives via a state evaluation function.

      The code below is provided as a guide.  You are welcome to change
      it in any way you see fit, so long as you don't touch our method
      headers.
    """


    def get_action(self, game_state):
        """
        You do not need to change this method, but you're welcome to.

        get_action chooses among the best options according to the evaluation function.

        Just like in the previous project, get_action takes a GameState and returns
        some Directions.X for some X in the set {North, South, West, East, Stop}
        """
        # Collect legal moves and successor states
        legal_moves = game_state.get_legal_actions()

        # Choose one of the best actions
        scores = [self.evaluation_function(game_state, action) for action in legal_moves]
        best_score = max(scores)
        best_indices = [index for index in range(len(scores)) if scores[index] == best_score]
        chosen_index = random.choice(best_indices) # Pick randomly among the best

        "Add more of your code here if you want to"

        return legal_moves[chosen_index]

    def evaluation_function(self, current_game_state, action):
        """
        Design a better evaluation function here.

        The evaluation function takes in the current and proposed successor
        GameStates (pacman.py) and returns a number, where higher numbers are better.

        The code below extracts some useful information from the state, like the
        remaining food (new_food) and Pacman position after moving (new_pos).
        new_scared_times holds the number of moves that each ghost will remain
        scared because of Pacman having eaten a power pellet.

        Print out these variables to see what you're getting, then combine them
        to create a masterful evaluation function.
        """
        # Useful information you can extract from a GameState (pacman.py)
        successor_game_state = current_game_state.generate_pacman_successor(action)
        new_pos = successor_game_state.get_pacman_position()
        new_food = successor_game_state.get_food()
        new_ghost_states = successor_game_state.get_ghost_states()
        new_scared_times = [ghost_state.scared_timer for ghost_state in new_ghost_states]
        
        "*** YOUR CODE HERE ***"
        score = successor_game_state.get_score()
        
        # Reward pacman for being closer to food
        # The smaller the distance, the better score
        food_list = new_food.as_list()
        food_score = 0
        for i in food_list:
          food_dist = util.manhattan_distance(i, new_pos)
          if food_dist != 0:
            food_score += 1 / food_dist
        
        return score + food_score
      
def score_evaluation_function(current_game_state):
    """
      This default evaluation function just returns the score of the state.
      The score is the same one displayed in the Pacman GUI.

      This evaluation function is meant for use with adversarial search agents
      (not reflex agents).
    """
    return current_game_state.get_score()

class MultiAgentSearchAgent(Agent):
    """
      This class provides some common elements to all of your
      multi-agent searchers.  Any methods defined here will be available
      to the MinimaxPacmanAgent, AlphaBetaPacmanAgent & ExpectimaxPacmanAgent.

      You *do not* need to make any changes here, but you can if you want to
      add functionality to all your adversarial search agents.  Please do not
      remove anything, however.

      Note: this is an abstract class: one that should not be instantiated.  It's
      only partially specified, and designed to be extended.  Agent (game.py)
      is another abstract class.
    """

    def __init__(self, eval_fn = 'score_evaluation_function', depth = '2'):
        self.index = 0 # Pacman is always agent index 0
        self.evaluation_function = util.lookup(eval_fn, globals())
        self.depth = int(depth)

class MinimaxAgent(MultiAgentSearchAgent):
    """
      Your minimax agent (question 2)
    """

    def get_action(self, game_state):
        """
          Returns the minimax action from the current game_state using self.depth
          and self.evaluation_function.

          Here are some method calls that might be useful when implementing minimax.

          game_state.get_legal_actions(agent_index):
            Returns a list of legal actions for an agent
            agent_index=0 means Pacman, ghosts are >= 1

          game_state.generate_successor(agent_index, action):
            Returns the successor game state after an agent takes an action

          game_state.get_num_agents():
            Returns the total number of agents in the game
        """
        "*** YOUR CODE HERE ***"
        
        # max function - maximize the score of Pacman
        def maximizer(state, depth):

          # Stop branching if at the max depth or game_state is a win or lose
          if depth == self.depth or state.is_win() or state.is_lose():
            return self.evaluation_function(state)

          max_value = float("-inf")
          pacman_legal_moves = state.get_legal_actions()

          # branch out using the min function, then take the max value of the result of the mins
          # use agent_index = 0 to retrieve Pacman
          for action in pacman_legal_moves:
            max_value = max(max_value, minimizer(state.generate_successor(0, action), depth, 1))            

          return max_value
        
        # min function - minimize the score of Pacman via other agents
        def minimizer(state, depth, agent_index):
          # Stop branching if at the max depth or game_state is a win or lose     
          if depth == self.depth or state.is_win() or state.is_lose():
            return self.evaluation_function(state)

          min_value = float("inf")
          agent_legal_moves = state.get_legal_actions(agent_index)
          
          # branch out using the max function, then take the min value of the result of the maxes
          # use agent_index > 0 to retrieve Ghosts
          
          # if agent_index is the last ghost, we have created all the min functions for the agents - switch to max functions for Pacman's turn
          if agent_index == state.get_num_agents() - 1:
            for action in agent_legal_moves:
              min_value = min(min_value, maximizer(state.generate_successor(agent_index, action), depth + 1))

          # create min functions for all agents
          else:
            for action in agent_legal_moves:
              min_value = min(min_value, minimizer(state.generate_successor(agent_index, action), depth, agent_index + 1))

          return min_value

        legal_moves = game_state.get_legal_actions()
        optimal_action = Directions.STOP
        value = float("-inf")

        for action in legal_moves:
          action_value = minimizer(game_state.generate_successor(0, action), 0, 1)
          if action_value > value:
            value = action_value
            optimal_action = action
          
        return optimal_action

class AlphaBetaAgent(MultiAgentSearchAgent):
    """
      Your minimax agent with alpha-beta pruning (question 3)
    """
    
    def get_action(self, game_state):
      
        # max function - maximize the score of Pacman
        def maximizer(state, depth, alpha, beta):

          # Stop branching if at the max depth or game_state is a win or lose
          if depth == self.depth or state.is_win() or state.is_lose():
            return self.evaluation_function(state)

          max_value = float("-inf")
          pacman_legal_moves = state.get_legal_actions()

          # branch out using the min function, then take the max value of the result of the mins
          # use agent_index = 0 to retrieve Pacman
          for action in pacman_legal_moves:
            max_value = max(max_value, minimizer(state.generate_successor(0, action), depth, 1, alpha, beta))            
            
            if max_value > beta:
              return max_value
            
            alpha = max(alpha, max_value)
          return max_value
        
        # min function - minimize the score of Pacman via other agents
        def minimizer(state, depth, agent_index, alpha, beta):
          # Stop branching if at the max depth or game_state is a win or lose     
          if depth == self.depth or state.is_win() or state.is_lose():
            return self.evaluation_function(state)

          min_value = float("inf")
          agent_legal_moves = state.get_legal_actions(agent_index)
          
          # branch out using the max function, then take the min value of the result of the maxes
          # use agent_index > 0 to retrieve Ghosts
          
          # if agent_index is the last ghost, we have created all the min functions for the agents - switch to max functions for Pacman's turn
          if agent_index == state.get_num_agents() - 1:
            for action in agent_legal_moves:
              min_value = min(min_value, maximizer(state.generate_successor(agent_index, action), depth + 1, alpha, beta))
              
              if min_value < alpha:
                return min_value
              
              beta = min(beta, min_value)

          # create min functions for all agents
          else:
            for action in agent_legal_moves:
              min_value = min(min_value, minimizer(state.generate_successor(agent_index, action), depth, agent_index + 1, alpha, beta))
              
              if min_value < alpha:
                return min_value
              
              beta = min(beta, min_value)
              
          return min_value

        legal_moves = game_state.get_legal_actions()
        optimal_action = Directions.STOP
        value = float("-inf")
        alpha = float("-inf")
        beta = float("inf")

        for action in legal_moves:
          action_value = minimizer(game_state.generate_successor(0, action), 0, 1, alpha, beta)
          if action_value > value:
            value = action_value
            optimal_action = action
          alpha = max(alpha, value)
        return optimal_action

class ExpectimaxAgent(MultiAgentSearchAgent):
    """
      Your expectimax agent (question 4)
    """

    def get_action(self, game_state):
        """
          Returns the expectimax action using self.depth and self.evaluation_function

          All ghosts should be modeled as choosing uniformly at random from their
          legal moves.
        """
        "*** YOUR CODE HERE ***"
        # max function - maximize the score of Pacman
        def maximizer(state, depth):

          # Stop branching if at the max depth or game_state is a win or lose
          if depth == self.depth or state.is_win() or state.is_lose():
            return self.evaluation_function(state)

          max_value = float("-inf")
          pacman_legal_moves = state.get_legal_actions()

          # branch out using the min function, then take the max value of the result of the mins
          # use agent_index = 0 to retrieve Pacman
          for action in pacman_legal_moves:
            max_value = max(max_value, expecter(state.generate_successor(0, action), depth, 1))            

          return max_value
        
        # min function - minimize the score of Pacman via other agents
        def expecter(state, depth, agent_index):
          # Stop branching if at the max depth or game_state is a win or lose     
          if depth == self.depth or state.is_win() or state.is_lose():
            return self.evaluation_function(state)

          expect_value = 0
          agent_legal_moves = state.get_legal_actions(agent_index)
          
          # branch out using the max function, then take the min value of the result of the maxes
          # use agent_index > 0 to retrieve Ghosts
          
          # if agent_index is the last ghost, we have created all the min functions for the agents - switch to max functions for Pacman's turn
          if agent_index == state.get_num_agents() - 1:
            for action in agent_legal_moves:
              expect_value += maximizer(state.generate_successor(agent_index, action), depth + 1)

          # create min functions for all agents
          else:
            for action in agent_legal_moves:
              expect_value += expecter(state.generate_successor(agent_index, action), depth, agent_index + 1)

          return expect_value / len(legal_moves)

        legal_moves = game_state.get_legal_actions()
        optimal_action = Directions.STOP
        value = float("-inf")

        for action in legal_moves:
          action_value = expecter(game_state.generate_successor(0, action), 0, 1)
          if action_value > value:
            value = action_value
            optimal_action = action
          
        return optimal_action

def better_evaluation_function(current_game_state):
    """
      Your extreme ghost-hunting, pellet-nabbing, food-gobbling, unstoppable
      evaluation function (question 5).

      DESCRIPTION: <write something here so we know what you did>
    """
    "*** YOUR CODE HERE ***"
    current_pos = current_game_state.get_pacman_position()
    current_food = current_game_state.get_food()
    capsule_pos = current_game_state.get_capsules()
    
    # generate the manhattan distance of every food in relation to pacman's position
    food_dists = []
    for food in current_food.as_list():
      food_dists.append(manhattan_distance(current_pos, food))
      
    # generate the manhattan distance of every capsule in relation to pacman's position
    capsule_dists = []
    for capsule in capsule_pos:
      capsule_dists.append(manhattan_distance(current_pos, capsule))
      
    score = 0
    x, y = current_pos
    
    # calculate ghost score
    ghost_score = 0
    for ghost_state in current_game_state.get_ghost_states():
      ghost_dist = manhattan_distance(current_pos, ghost_state.get_position())
      
      # if the ghost distance is close, increase score if scared and decrease score if normal
      if ghost_dist < 2:
        if ghost_state.scared_timer != 0:
          ghost_score += 1000 / (ghost_dist + 1)
        else:
          ghost_score -= 1000 / (ghost_dist + 1)
    
    # calculate capsule score - increase score the closer pacman is to the closet capsule
    capsule_score = 0
    if min(capsule_dists + [100] ) < 5:
      capsule_score += 500 / min(capsule_dists)
    
    # calculate food score - increase score the closer pacman is to the closest food and decrease score for the number of remaining foods
    food_score = 1 / min(food_dists + [100]) - len(food_dists) * 10
    
    return score + ghost_score + capsule_score + food_score
    
    

# Abbreviation
better = better_evaluation_function

