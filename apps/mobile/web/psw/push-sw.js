// Dedicated push service worker (scope /psw/) — separate from Flutter's SW so
// they don't fight over the root scope. Push delivery is per-registration, so a
// narrow scope is fine.
self.addEventListener('push', function (event) {
  let data = { title: 'Admin Market', body: '' };
  try { data = event.data.json(); } catch (e) {
    if (event.data) data.body = event.data.text();
  }
  event.waitUntil(
    self.registration.showNotification(data.title || 'Admin Market', {
      body: data.body || '',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: 'admin-market',
    })
  );
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (cl) {
      for (const c of cl) {
        if ('focus' in c) return c.focus();
      }
      if (clients.openWindow) return clients.openWindow('/');
    })
  );
});
