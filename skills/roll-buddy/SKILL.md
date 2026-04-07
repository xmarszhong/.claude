---
name: roll-buddy
description: Roll for the best Claude Code companion buddy matching specific criteria (species, rarity, shiny, stats, hat, eye). Searches millions of seeds and applies the best match to ~/.claude.json.
---

# Roll Buddy

Roll for a Claude Code companion (`/buddy`) that matches the user's desired criteria, then apply the best result.

## How It Works

The companion is deterministically generated from `userID` in `~/.claude.json` using a seeded PRNG. By brute-forcing seeds we can find any combination of traits.

## Generation Algorithm

```js
const SALT = "friend-2026-401";
// seed = Bun.hash(userId + SALT) & 0xffffffff  (Wyhash → Mulberry32 PRNG)

// Roll order:
// 1. rarity  (rng()*100): common 0-60, uncommon 60-85, rare 85-95, epic 95-99, legendary 99-100
// 2. species (rng()*18):  duck goose blob cat dragon octopus owl penguin turtle snail ghost axolotl capybara cactus robot rabbit mushroom chonk
// 3. eye     (rng()*6):   · ✦ × ◉ @ °
// 4. hat     (rng()*8):   none crown tophat propeller halo wizard beanie tinyduck
// 5. shiny   (rng()<0.01)
// 6. primaryStat  (rng()*5 → index into DEBUGGING PATIENCE CHAOS WISDOM SNARK)
// 7. secondaryStat (rng()*5, rerolled if == primary)
// 8. stats per slot:
//    primary:   min(100, 100 + floor(rng()*30))   → always 100
//    secondary: max(1,   40  + floor(rng()*15))   → 40-54
//    normal:    50 + floor(rng()*40)               → 50-89
```

**Stat constraints**: Primary is always 100. Secondary is 40-54. Normals are 50-89. Max spread = 46 (unavoidable).

## When This Skill Is Invoked

User runs `/roll-buddy` optionally followed by filter criteria, e.g.:
- `/roll-buddy` — find the best shiny legendary dragon overall
- `/roll-buddy DEBUGGING=100` — shiny legendary dragon with DEBUGGING as primary
- `/roll-buddy crown shiny legendary dragon SNARK=100`
- `/roll-buddy balanced` — smallest spread (most equal stats)
- `/roll-buddy DEBUGGING=100 crown` — D:100 + crown hat

## What To Do

1. **Parse the user's criteria** from the arguments. Defaults: species=dragon, rarity=legendary, shiny=true.

2. **Write and run a Bun script** that:
   - Rolls 500M seeds (prefix `"r"` + index, e.g. `"r0"`, `"r1"`, ...)
   - Filters by all user criteria
   - Sorts results by: total score DESC (or spread ASC if user asked for balanced)
   - Prints top 10 matches with full stat breakdown and userId

3. **Present results** in a table and ask which one to apply (or apply the top result if user said "just pick the best").

4. **Apply chosen result** by editing `~/.claude.json`:
   - Set `"userID"` to the winning seed string
   - Set `"companion": null` (forces re-hatch on next `/buddy`)

## Bun Script Template

```js
const SALT = "friend-2026-401";
const RARITIES = [{name:"common",weight:60},{name:"uncommon",weight:25},{name:"rare",weight:10},{name:"epic",weight:4},{name:"legendary",weight:1}];
const SPECIES = ["duck","goose","blob","cat","dragon","octopus","owl","penguin","turtle","snail","ghost","axolotl","capybara","cactus","robot","rabbit","mushroom","chonk"];
const EYES = ["·","✦","×","◉","@","°"];
const HATS = ["none","crown","tophat","propeller","halo","wizard","beanie","tinyduck"];
const STAT_NAMES = ["DEBUGGING","PATIENCE","CHAOS","WISDOM","SNARK"];

function mulberry32(seed) {
  let s = seed >>> 0;
  return function() { s |= 0; s = (s+1831565813)|0; let t = Math.imul(s^(s>>>15),1|s); t = (t+Math.imul(t^(t>>>7),61|t))^t; return ((t^(t>>>14))>>>0)/4294967296; };
}

function generate(userId) {
  const seed = Number(BigInt(Bun.hash(userId+SALT)) & 0xffffffffn);
  const rng = mulberry32(seed);
  const r = rng()*100; let acc=0,rarity;
  for (const item of RARITIES) { acc+=item.weight; if(r<acc){rarity=item.name;break;} }
  if(!rarity) rarity="legendary";
  const species = SPECIES[Math.floor(rng()*SPECIES.length)];
  const eye = EYES[Math.floor(rng()*EYES.length)];
  const hat = HATS[Math.floor(rng()*HATS.length)];
  const shiny = rng() < 0.01;
  const base=50, primaryIdx=Math.floor(rng()*5);
  let secondaryIdx=Math.floor(rng()*5);
  while(secondaryIdx===primaryIdx) secondaryIdx=Math.floor(rng()*5);
  const stats={};
  for(let i=0;i<5;i++){
    if(i===primaryIdx) stats[STAT_NAMES[i]]=Math.min(100,base+50+Math.floor(rng()*30));
    else if(i===secondaryIdx) stats[STAT_NAMES[i]]=Math.max(1,base-10+Math.floor(rng()*15));
    else stats[STAT_NAMES[i]]=base+Math.floor(rng()*40);
  }
  const vals=Object.values(stats);
  return {userId,rarity,species,eye,hat,shiny,stats,
    score:vals.reduce((a,b)=>a+b,0),
    spread:Math.max(...vals)-Math.min(...vals),
    primary:STAT_NAMES[primaryIdx]};
}

// --- INJECT FILTERS HERE ---
// Example filters:
// if(r.rarity!=="legendary") continue;
// if(r.species!=="dragon") continue;
// if(!r.shiny) continue;
// if(r.primary!=="DEBUGGING") continue;
// if(r.hat!=="crown") continue;

const results=[];
for(let i=0;i<500000000;i++){
  const r=generate("r"+i);
  // apply filters (replace this block)
  if(r.rarity!=="legendary") continue;
  if(r.species!=="dragon") continue;
  if(!r.shiny) continue;
  results.push(r);
}
// sort by score desc (or spread asc for balanced)
results.sort((a,b)=>b.score-a.score);
console.log(`Found ${results.length} matches in 500M rolls\n`);
for(const r of results.slice(0,10)){
  const s=r.stats;
  console.log(`  eye:${r.eye} hat:${r.hat.padEnd(10)} D:${String(s.DEBUGGING).padStart(3)} P:${String(s.PATIENCE).padStart(3)} C:${String(s.CHAOS).padStart(3)} W:${String(s.WISDOM).padStart(3)} S:${String(s.SNARK).padStart(3)}  score:${r.score}  id:${r.userId}`);
}
```

## Applying the Result

Edit `~/.claude.json` directly:
```json
"userID": "<winning-userId>",
"companion": null
```

Then tell the user to restart Claude Code and run `/buddy` to hatch.

## Notes

- 500M seeds takes ~60-90s in Bun on modern hardware. Tell the user it may take a minute.
- Shiny Legendary Dragon probability ≈ 1/180,000. Expect ~2,700 hits per 500M.
- All 100s is impossible — primary is always 100, secondary is always ≤54.
- The `"r"` prefix is just a namespace to avoid colliding with previous rolls (which used `"q"` and `"b"` prefixes).
