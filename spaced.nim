import os
import flatdb
import loki, strutils, options
from sequtils import zip
import json
import tables
import times
import Terminal
import osproc

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

proc print(text: string, color: ForegroundColor) =
  setForegroundColor(color)
  stdout.write(text)
  resetAttributes()

proc print(text: JsonNode, color: ForegroundColor) =
  setForegroundColor(color)
  stdout.write(text)
  resetAttributes()
      

proc addCard(): string =
  let ts = getTime().toUnixFloat()
  var front = ""
  var back = ""

  print("[card front]\n", color=fgGreen)
  while front == "":
    front = readLine(stdin)

  print("[card back]\n", color=fgBlue)
  while back == "":
    back = readLine(stdin)

  discard cards.append(%* {"front": front, "back": back, "created": ts, "next_review": ts + 10, "e_factor": 1.3, "n_review": 0,  "reviews": []})
  
  return "card added"


proc calculateEFactor(score: float, eFactor: float): float =
  if score == 0:
    return 0.01
  let delta = 0.1 - (5 - score) * (0.08 + (5 - score) * 0.02)
  return eFactor + delta


proc reviewCard(card: JsonNode): string =
  let startTime = getTime().toUnixFloat()
  print(card["front"], color=fgBlue)
  print("\n\npress any key to flip\n", color=fgGreen)
  var flip = readLine(stdin)
  print(card["back"], color=fgYellow)
  let answerTime = getTime().toUnixFloat()

  print("\n\nhow'd you do?\n", color=fgCyan)
  print("0 - complete blackout\n", color=fgRed)
  print("1 - incorrect response; the correct one remembered\n", color=fgYellow)
  print("2 - incorrect response; where the correct one seemed easy to recall\n", color=fgCyan)
  print("3 - correct response recalled with serious difficulty\n", color=fgMagenta)
  print("4 - correct respoinse after a hesitation\n", color=fgBlue)
  print("5 - perfect response\n", color=fgGreen)

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


  print("\n\npress any key to continue, enter q to quit\n", color=fgGreen)
  flip = readLine(stdin)

  if flip == "q":
    write(stdout, "Bye!\n")
    return "quit"


  discard execCmd "clear"


proc reviewCards(): string = 
  let ts = getTime().toUnixFloat()

  var reviewable = cards.query lower("next_review", ts)

  for card in reviewable:
    var res = reviewCard(card)
    if res == "quit":
      break

  cards.flush()

loki(handler, input):
  do_add:
    var added = addCard()
    print(added, color=fgGreen)
    discard execCmd "clear"
  do_review:
    discard execCmd "clear"
    var review = reviewCards()
    return true
  do_quit:
    write(stdout, "Bye!\n")
    return true
  do_exit:
    write(stdout, "Bye!\n")
    return true
  do_EOF:
    write(stdout, "Bye!\n")
    return true
  default:
    write(stdout, "*** Unknown command: ", input.text, " ***\n")


let command = newLoki(
  prompt="[spaced] ",
  handler=handler,
  intro="welcome to spaced"
)

command.cmdLoop
