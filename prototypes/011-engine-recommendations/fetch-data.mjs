// PROTOTYPE script — throwaway. Resolves Favourites + Candidates to MusicBrainz
// release-group MBIDs and pulls their tags/genres/first-release-date, then
// writes data.json for the demo HTML to embed. Rate-limited to 1 req/s per
// ticket 002's finding (MusicBrainz API is 1 req/s per IP).
//
// Run: node fetch-data.mjs

import { favourites, candidates } from "./albums.mjs";
import { writeFile } from "node:fs/promises";

const UA = "music-discovery-prototype/0.1 (https://github.com/sameames18/music-discovery; wayfinder ticket 011)";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function mbFetch(url) {
  const res = await fetch(url, { headers: { "User-Agent": UA, Accept: "application/json" } });
  if (!res.ok) throw new Error(`${res.status} ${res.statusText} for ${url}`);
  return res.json();
}

async function resolveAlbum({ title, artist }) {
  const q = `releasegroup:"${title.replace(/"/g, '\\"')}" AND artist:"${artist.replace(/"/g, '\\"')}"`;
  const searchUrl = `https://musicbrainz.org/ws/2/release-group/?query=${encodeURIComponent(q)}&fmt=json&limit=1`;
  await sleep(1100);
  const search = await mbFetch(searchUrl);
  const hit = search["release-groups"]?.[0];
  if (!hit) {
    console.warn(`  NO MATCH: "${title}" — ${artist}`);
    return null;
  }

  const lookupUrl = `https://musicbrainz.org/ws/2/release-group/${hit.id}?inc=tags+genres+artist-credits&fmt=json`;
  await sleep(1100);
  const full = await mbFetch(lookupUrl);

  const tags = (full.tags || [])
    .filter((t) => t.count > 0)
    .sort((a, b) => b.count - a.count)
    .map((t) => t.name);
  const genres = (full.genres || [])
    .filter((g) => g.count > 0)
    .sort((a, b) => b.count - a.count)
    .map((g) => g.name);

  return {
    mbid: full.id,
    title: full.title,
    artist: (full["artist-credit"] || []).map((c) => c.name).join(", ") || artist,
    year: (full["first-release-date"] || "").slice(0, 4) || null,
    // MusicBrainz tags and genres are both folksonomy-style; merge and
    // de-dupe since the split between them is inconsistent in practice.
    tags: [...new Set([...genres, ...tags])],
  };
}

async function resolveAll(list, label) {
  const out = [];
  for (const [i, album] of list.entries()) {
    process.stdout.write(`[${label} ${i + 1}/${list.length}] ${album.title} — ${album.artist} ... `);
    try {
      const resolved = await resolveAlbum(album);
      if (resolved) {
        console.log(`OK (${resolved.tags.length} tags)`);
        out.push(resolved);
      } else {
        console.log("skipped");
      }
    } catch (err) {
      console.log(`ERROR: ${err.message}`);
    }
  }
  return out;
}

const resolvedFavourites = await resolveAll(favourites, "favourite");
const resolvedCandidates = await resolveAll(candidates, "candidate");

await writeFile(
  new URL("./data.json", import.meta.url),
  JSON.stringify({ favourites: resolvedFavourites, candidates: resolvedCandidates }, null, 2)
);

console.log(
  `\nDone. ${resolvedFavourites.length}/${favourites.length} favourites, ${resolvedCandidates.length}/${candidates.length} candidates resolved. Wrote data.json.`
);
