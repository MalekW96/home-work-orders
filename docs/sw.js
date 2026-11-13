/* I Got This service worker (generated into docs/sw.js by scripts/sync-web.sh). Version: 2.6.2.0 */
const CACHE='igotthis-2.6.2.0';
const CORE=['./','index.html','manifest.webmanifest','apple-touch-icon.png','icon-192.png','icon-512.png','libs/jspdf.umd.min.js','libs/jspdf.plugin.autotable.min.js'];

self.addEventListener('install',e=>{
  e.waitUntil(caches.open(CACHE).then(c=>c.addAll(CORE.map(u=>new Request(u,{cache:'reload'})))).then(()=>self.skipWaiting()));
});
self.addEventListener('activate',e=>{
  e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k.startsWith('igotthis-')&&k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim()));
});
self.addEventListener('fetch',e=>{
  const req=e.request; if(req.method!=='GET') return;
  const url=new URL(req.url);
  if(url.origin===location.origin){
    // Pages: try the network first so a new version arrives, fall back to the saved copy when offline.
    if(req.mode==='navigate'){
      // Only the app itself is kept for offline use. Other pages on this site (such as /site/) load normally.
      const root=new URL('./',location).pathname; if(url.pathname!==root&&url.pathname!==root+'index.html') return;
      e.respondWith(fetch(req.url,{cache:'no-cache'}).then(r=>{ const copy=r.clone(); caches.open(CACHE).then(c=>c.put('index.html',copy)); return r; }).catch(()=>caches.match('index.html')));
      return;
    }
    e.respondWith(caches.match(req).then(hit=>hit||fetch(req).then(r=>{ const copy=r.clone(); caches.open(CACHE).then(c=>c.put(req,copy)); return r; })));
    return;
  }
  // Web fonts: keep whatever was loaded last time.
  if(url.hostname==='fonts.googleapis.com'||url.hostname==='fonts.gstatic.com'){
    e.respondWith(caches.open(CACHE).then(c=>c.match(req).then(hit=>{
      const net=fetch(req).then(r=>{ c.put(req,r.clone()); return r; }).catch(()=>hit);
      return hit||net;
    })));
  }
});
