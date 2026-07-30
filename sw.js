const CACHE = 'pooleman-v1';
const ASSETS = ['./', './index.html', './manifest.json', './icon-192.png', './icon-512.png'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
  );
});

self.addEventListener('fetch', (e) => {
  // network-first for Supabase API calls, cache-first for the app shell
  if (e.request.url.includes('supabase.co')) return;
  e.respondWith(caches.match(e.request).then((r) => r || fetch(e.request)));
});
