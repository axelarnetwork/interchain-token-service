const fs = require('fs');
const path = require('path');

const parent_dir = 'docs';
const parent_output = path.join(parent_dir, 'index.md');

function generateIndex(dir, output) {
  let content = '# Solidity API\n\n';

  // List all Markdown files in the directory under "Contracts"
  const files = fs.readdirSync(dir).filter(file => file.endsWith('.md') && file !== 'index.md');
  if (files.length > 0) {
    content += '## Contracts\n';
    files.forEach(file => {
      const title = path.parse(file).name;
      content += `- [${title}](${file})\n`;
    });
  }

  // List all subdirectories under "Directories"
  const subdirs = fs.readdirSync(dir).filter(subdir => fs.statSync(path.join(dir, subdir)).isDirectory());
  if (subdirs.length > 0) {
    content += '\n## Directories\n';
    subdirs.forEach(subdir => {
      let child_dir = path.join(dir, subdir);
      let child_output = path.join(child_dir, 'index.md');
      generateIndex(child_dir, child_output);
      content += `- [${subdir}](${subdir}/index.md)\n`;
    });
  }

  fs.writeFileSync(output, content);
  console.log(`Generated ${output}`);
}

generateIndex(parent_dir, parent_output);