import os
import flatdb
from sequtils import zip
import json
import strutils
import tables
import times
import Terminal
import osproc
import scoring
import styleprint

discard execCmd "clear"

const homeDir = getHomeDir()
var spacedDir = homeDir & "/.spaced"
var db = spacedDir & "/deck.db"

if not fileExists(db):
  echo "welcome to spaced"
  echo "let's get started by creating a db to store our deck"
  if not dirExists(spacedDir):
    createDir(spacedDir)
  writeFile(db, "")

var cards = newFlatDb(path=db, inmemory=false)
discard cards.load()

proc add(): string =
  let ts = getTime().toUnixFloat()
  var front = ""
  var back = ""

  print("[card front]\n", color="green")
  while front == "":
    front = readLine(stdin)

  print("[card back]\n", color="blue")
  while back == "":
    back = readLine(stdin)

  discard cards.append(%* {"front": front, "back": back, "created": ts, "next_review": ts + 10, "e_factor": 1.3, "n_review": 0,  "reviews": []})
  
  return "card added"


proc reviewCard(card: JsonNode): string =
  let startTime = getTime().toUnixFloat()
  print(card["front"].getStr(), color="blue")
  print("\n\npress any key to flip\n", color="green")
  var flip = readLine(stdin)
  print(card["back"].getStr(), color="yellow")
  let answerTime = getTime().toUnixFloat()

  print("\n\nhow'd you do?\n", color="cyan")
  print("0 - complete blackout\n", color="red")
  print("1 - incorrect response; the correct one remembered\n", color="yellow")
  print("2 - incorrect response; where the correct one seemed easy to recall\n", color="cyan")
  print("3 - correct response recalled with serious difficulty\n", color="magenta")
  print("4 - correct respoinse after a hesitation\n", color="blue")
  print("5 - perfect response\n", color="green")

  var scr = ""
  while scr notin @["0", "1", "2", "3", "4", "5"]:
    scr = readLine(stdin)

  let score = parseFloat(scr)

  var eFactor = card["e_factor"].getFloat(1.3)

  var newEFactor = calculateEFactor(score, eFactor)

  var numReviews = card["n_review"].getInt()
  numReviews += 1

  let nextReviewDays = numReviews.float * newEFactor
  let nextReview = nextReviewDays * 86400.0 + answerTime


  echo "next review scheduled in ", nextReviewDays, " days"

  card["score"] = % score
  card["e_factor"] = % newEFactor
  card["n_review"] = % numReviews
  card["next_review"] = % nextReview


  print("\n\npress any key to continue, enter q to quit\n", color="green")
  flip = readLine(stdin)

  if flip == "q":
    write(stdout, "Bye!\n")
    return "quit"


  discard execCmd "clear"


proc review*(): string = 
  let ts = getTime().toUnixFloat()

  var reviewable = cards.query lower("next_review", ts)

  for card in reviewable:
    var res = reviewCard(card)
    if res == "quit":
      break

  cards.flush()

when isMainModule:
  import cligen

  dispatchMulti([spaced.add], [review])
