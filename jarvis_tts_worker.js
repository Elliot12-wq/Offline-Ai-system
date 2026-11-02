// JARVIS TTS backend (Cloudflare Worker). Keeps the Google Cloud API key server-side.
// Deploy:  npx wrangler deploy        (name = "jarvis-tts", main = "jarvis_tts_worker.js", compatibility_date = "2025-01-01")
// Secret:  npx wrangler secret put GOOGLE_TTS_KEY     (Google Cloud API key with "Cloud Text-to-Speech API" enabled)
// Optional vars: VOICE (default en-GB-Neural2-B, British male), RATE (default 1.0), PITCH (default -1.5)
// In the script: Main page > "Jarvis voice server" box, or say: "Jarvis, set voice server https://jarvis-tts.<you>.workers.dev"
const MAX_CHARS = 450;

export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") return new Response(null, { status: 204 });
    if (request.method !== "GET") return new Response("method not allowed", { status: 405 });
    const text = (new URL(request.url).searchParams.get("t") || "").trim().slice(0, MAX_CHARS);
    if (!text) return new Response("missing t", { status: 400 });
    if (!env.GOOGLE_TTS_KEY) return new Response("GOOGLE_TTS_KEY is not set", { status: 500 });

    const voice = env.VOICE || "en-GB-Neural2-B";
    const rate = parseFloat(env.RATE || "1.0");
    const pitch = parseFloat(env.PITCH || "-1.5");

    // identical sentences are served from Cloudflare's edge cache: no repeat Google calls
    const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(`${voice}|${rate}|${pitch}|${text}`));
    const key = new Request("https://jarvis-tts.cache/" + [...new Uint8Array(digest)].map(b => b.toString(16).padStart(2, "0")).join(""));
    const cache = caches.default;
    const hit = await cache.match(key);
    if (hit) return hit;

    const res = await fetch("https://texttospeech.googleapis.com/v1/text:synthesize", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Goog-Api-Key": env.GOOGLE_TTS_KEY },
      body: JSON.stringify({
        input: { text },
        voice: { languageCode: "en-GB", name: voice },
        audioConfig: { audioEncoding: "MP3", speakingRate: rate, pitch, sampleRateHertz: 24000 },
      }),
    });
    if (!res.ok) return new Response("tts upstream error " + res.status, { status: 502 });
    const { audioContent } = await res.json();
    if (!audioContent) return new Response("empty audio", { status: 502 });

    const bin = atob(audioContent);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    const out = new Response(bytes, { headers: { "Content-Type": "audio/mpeg", "Cache-Control": "public, max-age=31536000" } });
    ctx.waitUntil(cache.put(key, out.clone()));
    return out;
  },
};
