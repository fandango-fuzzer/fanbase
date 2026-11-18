// Parses one file with uvl-parser's JavaScript API, `new FeatureModel(path)`: exit 0 if it parses.
// The package is imported from UVL_PARSER_ROOT/js (a checkout with `make js_parser` and `npm install` done).
import path from "node:path";
import { pathToFileURL } from "node:url";

const root = process.env.UVL_PARSER_ROOT;
const { FeatureModel } = await import(pathToFileURL(path.join(root, "js", "index.js")).href);

try {
  new FeatureModel(process.argv[2]);
} catch (error) {
  const message = String(error?.message ?? error).split(/\s+/).join(" ");
  console.error(`${error?.name ?? "Error"}: ${message}`);
  process.exit(1);
}
