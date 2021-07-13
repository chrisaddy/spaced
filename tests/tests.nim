# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import ../scoring
import ../styleprint


test "EFactor for 0":
  var score = 0.0
  var eFactorOld = 1.0

  check: scoring.calculateEFactor(score, eFactorOld) == 0.01

  score = 0.0
  eFactorOld = 8.34
  check: scoring.calculateEFactor(score, eFactorOld) == 0.01
