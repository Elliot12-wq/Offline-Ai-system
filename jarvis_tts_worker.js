// JARVIS TTS backend (Cloudflare Worker). Keeps the Google Cloud API key server-side.
// Engine order: 1) Gemini-TTS (takes a written style direction, so it can actually perform a British butler)
//               2) Chirp 3 HD (same voice name, natural but undirected)   3) Neural2 en-GB male (plain safety net)
// Deploy:  npx wrangler deploy        (see wrangler.toml)
// Secret:  npx wrangler secret put GOOGLE_TTS_KEY     (Google Cloud API key with "Cloud Text-to-Speech API" enabled, billing on)
// Optional vars:
//   VOICE  a bare name = Gemini/Chirp voice (default "Charon"; other male options: Algieba, Orus, Rasalgethi, Alnilam, Sadaltager, Schedar)
//          a full name such as "en-GB-Neural2-D" = that classic voice only
//   MODEL  default "gemini-2.5-flash-tts" ("gemini-2.5-pro-tts" is slower but more controllable)
//   STYLE  overrides the butler direction below
//   RATE / PITCH  only used by the Chirp and Neural2 fallbacks (defaults 0.95 / -3.0)
// In the script: Main page > "Jarvis voice server" box, or say: "Jarvis, set voice server https://jarvis-tts.<you>.workers.dev"
const MAX_CHARS = 450;
const BUTLER =
  "You are Jarvis, a refined English butler and personal valet. Speak in a calm, warm, impeccably polite British accent " +
  "(received pronunciation) with a low, smooth, unhurried baritone delivery. Dry, understated wit and quiet confidence. " +
  "Never robotic, never theatrical or sing-song, never rushed. Let the pauses at commas and full stops breathe. " +
  "Say the following exactly as written:";

export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") return new Response(null, { status: 204 });
    if (request.method !== "GET") return new Response("method not allowed", { status: 405 });
    const text = (new URL(request.url).searchParams.get("t") || "").trim().slice(0, MAX_CHARS);
    if (!text) return new Response("missing t", { status: 400 });
    if (!env.GOOGLE_TTS_KEY) return new Response("GOOGLE_TTS_KEY is not set", { status: 500 });

    const v = env.VOICE || "Charon";
    const model = env.MODEL || "gemini-2.5-flash-tts";
    const style = env.STYLE || BUTLER;
    const rate = parseFloat(env.RATE || "0.95");
    const pitch = parseFloat(env.PITCH || "-3.0");

    // identical sentences are served from Cloudflare's edge cache: no repeat Google calls (and a line keeps the same take)
    const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(`${v}|${model}|${style}|${rate}|${pitch}|${text}`));
    const key = new Request("https://jarvis-tts.cache/" + [...new Uint8Array(digest)].map(b => b.toString(16).padStart(2, "0")).join(""));
    const cache = caches.default;
    const hit = await cache.match(key);
    if (hit) return hit;

    const classic = (name) => ({
      id: "neural2",
      input: { text },
      voice: { languageCode: name.split("-").slice(0, 2).join("-"), name },
      audioConfig: { audioEncoding: "MP3", speakingRate: rate, pitch, sampleRateHertz: 24000 },
    });
    const attempts = [];
    if (!v.includes("-")) {
      attempts.push({
        id: "gemini",
        input: { text, prompt: style },
        voice: { languageCode: "en-GB", name: v, modelName: model },
        audioConfig: { audioEncoding: "MP3" },
      });
      attempts.push({
        id: "chirp",
        input: { text },
        voice: { languageCode: "en-GB", name: `en-GB-Chirp3-HD-${v}` },
        audioConfig: { audioEncoding: "MP3", speakingRate: rate },
      });
      attempts.push(classic("en-GB-Neural2-B"));
    } else {
      attempts.push(classic(v));
      if (v !== "en-GB-Neural2-B") attempts.push(classic("en-GB-Neural2-B"));
    }

    let res, used = -1, lastErr = "";
    for (let i = 0; i < attempts.length; i++) {
      const a = attempts[i];
      const r = await fetch("https://texttospeech.googleapis.com/v1/text:synthesize", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Goog-Api-Key": env.GOOGLE_TTS_KEY },
        body: JSON.stringify({ input: a.input, voice: a.voice, audioConfig: a.audioConfig }),
      });
      if (r.ok) { res = r; used = i; break; }
      lastErr = `${a.id} ${r.status}: ` + (await r.text()).replace(/\s+/g, " ").slice(0, 160);
    }
    if (!res) return new Response("tts upstream error " + lastErr, { status: 502 });
    const { audioContent } = await res.json();
    if (!audioContent) return new Response("empty audio", { status: 502 });

    const bin = atob(audioContent);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    // only the first-choice engine is cached for a year; a fallback take is never stored under the first-choice key
    const out = new Response(bytes, { headers: { "Content-Type": "audio/mpeg", "X-Jarvis-Engine": attempts[used].id, "Cache-Control": used === 0 ? "public, max-age=31536000" : "no-store" } });
    if (used === 0) ctx.waitUntil(cache.put(key, out.clone()));
    return out;
  },
};
