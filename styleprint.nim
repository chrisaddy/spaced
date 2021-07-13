import Terminal
import json

proc textColor(color: string): ForegroundColor =
  case color:
    of "blue":
      return fgBlue
    of "cyan":
      return fgCyan
    of "green":
      return fgGreen
    of "magenta":
      return fgMagenta
    of "red":
      return fgRed
    of "yellow":
      return fgYellow

proc print*(text: string, color: string): string =
  let foreground = textColor(color)
  setForegroundColor(foreground)
  stdout.write(text)
  resetAttributes()
  return text

proc print*(obj: JsonNode, color: string): JsonNode =
  let foreground = textColor(color)
  setForegroundColor(foreground)
  stdout.write(obj)
  resetAttributes()
  return obj
