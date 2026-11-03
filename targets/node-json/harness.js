// Ask V8 about a file: exit 0 if JSON.parse reads it, else say why and exit 1.
//
// The file is decoded as UTF-8, and a byte that is not is an error (JSON is UTF-8, and Node would otherwise put in a
// replacement character). Where in the text the error is ("at position 9") is left out of the reason.
const fs = require("fs");

try {
  const text = new TextDecoder("utf-8", { fatal: true }).decode(fs.readFileSync(process.argv[2]));
  JSON.parse(text);
} catch (error) {
  const message = String(error.message).split("\n")[0].replace(/ (at|in JSON at) position \d+.*$/, "").replace(/ \(line \d+ column \d+\)$/, "");
  process.stderr.write(`${error.name}: ${message}\n`);
  process.exit(1);
}
