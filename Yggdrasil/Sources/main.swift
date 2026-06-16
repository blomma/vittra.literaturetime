// Usage: Yggdrasil [input.json] [output.store]
// Falls back to the canonical quote repository paths when no arguments are given.
let arguments = CommandLine.arguments
let fromFile =
    arguments.count > 1
    ? arguments[1]
    : "/Users/blomma/Projects/literature/translated.quotes.literaturetime/literatureTimes.json"
let toStore =
    arguments.count > 2
    ? arguments[2]
    : "/Users/blomma/Projects/literature/translated.quotes.literaturetime/literatureTimes.store"

importLiteratureTime(fromFile: fromFile, toStore: toStore)
