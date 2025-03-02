import * as esbuild from "esbuild";
import { globSync } from "glob";
import path from "path";
import * as dotenv from "dotenv";

dotenv.config();

const themeName = process.env.THEME_NAME ?? "base-theme";

const entryPoints = globSync("./src/blocks/**/*.{ts,tsx}", { ignore: "./src/blocks/**/*.d.ts" });

await esbuild.build({
    entryPoints: entryPoints.map(block =>  {
        const dirPath = path.dirname(block, path.extname(block));
        const folder = path.basename(dirPath);
        return {
            in:block,
            out: `${folder}/editor`
        }
    }),
    bundle: true,
    minify: false,
    sourcemap: true,
    outdir: `./web/wp-content/themes/${themeName}/inc/blocks`,
});

