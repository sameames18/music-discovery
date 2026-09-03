// PROTOTYPE script — throwaway. Retries any Favourite/Candidate that failed
// (503s, no-match) in the first pass, with a slower rate and a couple of
// retries per item. Merges results into the existing data.json.

import { favourites, candidates } from "./albums.mjs";
import { readFile, writeFile } from "node:fs/promises";

const UA = "music-discovery-prototype/0.1 (https://github.com/sameames18/music-discovery; wayfinder ticket 011)";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function mbFetch(url, attempt = 1) {
  const res = await fetch(url, { headers: { "User-Agent": UA, Accept: "application/json" } });
  if (res.status === 503 && attempt <= 4) {
    await sleep(3000 * attempt);
    return mbFetch(url, attempt + 1);
  }
  if (!res.ok) throw new Error(`${res.status} ${res.statusText} for ${url}`);
  return res.json();
}

async function resolveAlbum({ title, artist }) {
  const q = `releasegroup:"${title.replace(/"/g, '\\"')}" AND artist:"${artist.replace(/"/g, '\\"')}"`;
  const searchUrl = `https://musicbrainz.org/ws/2/release-group/?query=${encodeURIComponent(q)}&fmt=json&limit=1`;
  await sleep(1500);
  const search = await mbFetch(searchUrl);
  const hit = search["release-groups"]?.[0];
  if (!hit) return null;

  const lookupUrl = `https://musicbrainz.org/ws/2/release-group/${hit.id}?inc=tags+genres+artist-credits&fmt=json`;
  await sleep(1500);
  const full = await mbFetch(lookupUrl);

  const tags = (full.tags || []).filter((t) => t.count > 0).sort((a, b) => b.count - a.count).map((t) => t.name);
  const genres = (full.genres || []).filter((g) => g.count > 0).sort((a, b) => b.count - a.count).map((g) => g.name);

  return {
    mbid: full.id,
    title: full.title,
    artist: (full["artist-credit"] || []).map((c) => c.name).join(", ") || artist,
    year: (full["first-release-date"] || "").slice(0, 4) || null,
    tags: [...new Set([...genres, ...tags])],
  };
}

const dataPath = new URL("./data.json", import.meta.url);
const data = JSON.parse(await readFile(dataPath, "utf-8"));

async function fillMissing(sourceList, resolvedList, label) {
  const resolvedTitles = new Set(resolvedList.map((r) => r.title.toLowerCase()));
  const missing = sourceList.filter((a) => !resolvedTitles.has(a.title.toLowerCase()));
  console.log(`${label}: ${missing.length} missing of ${sourceList.length}`);
  for (const album of missing) {
    process.stdout.write(`  retrying "${album.title}" — ${album.artist} ... `);
    try {
      const resolved = await resolveAlbum(album);
      if (resolved) {
        console.log(`OK (${resolved.tags.length} tags)`);
        resolvedList.push(resolved);
      } else {
        console.log("still no match");
      }
    } catch (err) {
      console.log(`ERROR: ${err.message}`);
    }
  }
}

await fillMissing(favourites, data.favourites, "favourites");
await fillMissing(candidates, data.candidates, "candidates");

await writeFile(dataPath, JSON.stringify(data, null, 2));
console.log(`\nDone. ${data.favourites.length}/${favourites.length} favourites, ${data.candidates.length}/${candidates.length} candidates resolved.`);
