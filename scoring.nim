
proc calculateEFactor*(score: float, eFactor: float): float =
  if score == 0:
    return 0.01
  let delta = 0.1 - (5.0 - score) * (0.08 + (5.0 - score) * 0.02)
  return eFactor + delta
