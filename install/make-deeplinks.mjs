// Regenerates install/deeplinks.json from pets/*/pet.json.
//   node install/make-deeplinks.mjs
// Each link opens the "Install <name>?" dialog in the Codex / ChatGPT desktop app.
// The app only accepts these four parameters and an https imageUrl, so the spritesheet is served from raw.githubusercontent.com
// (the repository has to be public for the links to work).
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const root = fileURLToPath(new URL('..', import.meta.url));
const RAW = 'https://raw.githubusercontent.com/nett0eth/weird-cats-plush-pets/main/pets';
const links = {};
for (const dir of readdirSync(join(root, 'pets')).filter(d => d.startsWith('weird-cats-plush-')).sort()) {
  const pet = JSON.parse(readFileSync(join(root, 'pets', dir, 'pet.json'), 'utf8'));
  const q = new URLSearchParams();
  q.set('name', pet.displayName);
  q.set('description', pet.description);
  q.set('imageUrl', `${RAW}/${dir}/${pet.spritesheetPath}`);
  q.set('spriteVersionNumber', String(pet.spriteVersionNumber));
  // URLSearchParams writes spaces as "+"; use %20 so every parser agrees
  links[dir.replace('weird-cats-plush-', '')] = `codex://pets/install?${q.toString().replace(/\+/g, '%20')}`;
}
writeFileSync(join(root, 'install', 'deeplinks.json'), JSON.stringify(links, null, 2) + '\n');
console.log(`wrote ${Object.keys(links).length} links`);
