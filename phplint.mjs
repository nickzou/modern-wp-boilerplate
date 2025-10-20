import { globSync } from "glob";
import * as dotenv from "dotenv";
import { execSync } from "child_process";

dotenv.config();

const themeName = process.env.THEME_NAME ?? "base-theme";

const phpFiles = globSync([
        `./web/wp-content/themes/${themeName}/**/*.php`,
    ], 
    {ignore:
        `./web/wp-content/themes/${themeName}/vendor/**/*.php`
    });


console.log(`PHP Lint: Found ${phpFiles.length} PHP files in ${themeName}`);

phpFiles.forEach((file) => {
    try {
        console.log(`Checking ${file}...`);
        execSync(`php -l "${file}"`, { stdio: "inherit" });
    } catch (error) {
        // PHP error output is already shown via stdio: 'inherit'
    }
});

console.log("Finished checking all PHP files");
