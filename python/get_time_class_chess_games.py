#!/usr/bin/env python3

import datetime
import json
import re
import requests # python -m pip install requests
import sys

# Check arguments, show example on usage
if len(sys.argv) == 3:
  player_name = str(sys.argv[1]).strip().lower()
  time_class = str(sys.argv[2]).strip().lower()
else:
  print("\nPlease submit only two arguments!")
  print("First argument is the player name on chess.com, second is time class of the game (daily, rapid, blitz, bullet)")
  print(f"Example: {sys.argv[0]} hikaru rapid\n")
  sys.exit(1)

# Validate time_class
if not re.search(r'^(daily|rapid|blitz|bullet)$', time_class):
  print(f"\nERROR: Time Class: {time_class} is NOT daily, rapid, blitz, or bullet, exiting...\n")
  sys.exit(1)

# Go through chess.com player's monthly archives, add to collected games if found
collected_games = []
game_archives = requests.get(f"https://api.chess.com/pub/player/{player_name}/games/archives")
game_archives_dict = json.loads(game_archives.content.decode('utf-8'))
if 'archives' in game_archives_dict:
  for month in game_archives_dict['archives']:
    print(f"Processing {month}...")
    month_games = requests.get(month)
    month_games_dict = json.loads(month_games.content.decode('utf-8'))
    for game in month_games_dict['games']:
      if game['time_class'] == time_class:
        collected_games.append(f"{game['pgn']}\n")
else:
  print(f"\nERROR: Did NOT find any game archives for {player_name}, exiting...\n")
  sys.exit(1)

# Prepare unique output filename
datetime_string = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
filename = f"{datetime_string}_{player_name}_{time_class}.pgn"

# Output games if found
if collected_games:
  output_file = open(filename, "w")
  for game in collected_games:
    output_file.writelines(game)
  print(f"\n{filename} has been generated!\n")
  output_file.close()
else:
  print(f"\nScript did NOT find any {player_name} {time_class} games, exiting...\n")
