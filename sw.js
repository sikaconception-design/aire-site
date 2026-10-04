// Mémoire hors connexion du site AIRE : réseau d'abord, copie en réserve si le réseau est coupé.
const C = 'aire-v1';
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(
  caches.keys().then(k => Promise.all(k.filter(x => x !== C).map(x => caches.delete(x)))).then(() => self.clients.claim())
));
self.addEventListener('fetch', e => {
  const r = e.request, u = new URL(r.url);
  const api = u.hostname.endsWith('supabase.co') && !u.pathname.startsWith('/storage/v1/object/public/');
  if (r.method !== 'GET' || api || r.headers.has('range')) return;
  e.respondWith(
    fetch(r).then(res => {
      if (res && (res.ok || res.type === 'opaque')) { const cp = res.clone(); caches.open(C).then(c => c.put(r, cp)).catch(() => {}); }
      return res;
    }).catch(() => caches.match(r).then(m => m || (r.mode === 'navigate' ? caches.match('index.html').then(i => i || caches.match('./')) : Response.error())))
  );
});
