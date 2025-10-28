//CURRENTLY NOT IN USE
import { globSync } from "glob";
import path from "path";
import * as dotenv from "dotenv";

dotenv.config();

const themeName = process.env.THEME_SLUG ?? "base-theme";

const entryPoints = globSync("./src/blocks/**/*.json");

entryPoints.forEach(filePath => {
    const blockDir = path.dirname(filePath);
  
    // Extract the block name (last part of the directory path)
    const blockName = path.basename(blockDir); 

    const destDir = `./web/wp-content/themes/${themeName}/inc/blocks/${blockName}`;

    // Read the source file
    const blockJson = fs.readFileSync(filePath, 'utf8');
  
    // Parse the JSON to update any properties if needed
    const blockData = JSON.parse(blockJson);

    // Write the updated JSON to the destination
    fs.writeFileSync(
        path.join(destDir, 'block.json'),
        JSON.stringify(blockData, null, 2)
    );
    
    console.log(`Copied and updated: ${blockName} block`);
});

console.log(`All blocks copied to the blocks directory`);

