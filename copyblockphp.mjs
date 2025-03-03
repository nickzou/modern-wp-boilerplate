import { globSync } from "glob";
import path from "path";
import * as dotenv from "dotenv";

dotenv.config();

const themeName = process.env.THEME_NAME ?? "base-theme";

const entryPoints = globSync("./src/blocks/**/*.php");

entryPoints.forEach(filePath => {
    const blockDir = path.dirname(filePath);
  
    // Extract the block name (last part of the directory path)
    const blockName = path.basename(blockDir); 

    const destDir = `./web/wp-content/themes/${themeName}/inc/blocks/${blockName}`;

    // Parse the JSON to update any properties if needed
    const phpContent = fs.readFileSync(filePath, 'utf8');

    // Write the updated JSON to the destination
    fs.writeFileSync(
        path.join(destDir, 'register.php'),
        phpContent
    );
    
    console.log(`Copied and updated: ${blockName} register.php`);
});

console.log(`All register.php copied to the blocks directory`);


