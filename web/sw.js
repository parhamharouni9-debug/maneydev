// Retire the legacy PoolMan PWA service worker and its cached HTML shell.
// Flutter currently uses its network-loaded bootstrap; API requests stay online.
self.addEventListener('install', (event) => {
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(
      keys.filter((key) => key.startsWith('pooleman-'))
        .map((key) => caches.delete(key)),
    );
    await self.registration.unregister();
    const windows = await self.clients.matchAll({ type: 'window' });
    await Promise.all(windows.map((client) => client.navigate(client.url)));
  })());
});
