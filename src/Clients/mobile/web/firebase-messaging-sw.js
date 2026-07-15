importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

const messagingReady = fetch('/firebase-config.json', { cache: 'no-store' })
  .then((response) => (response.ok ? response.json() : null))
  .then((config) => {
    if (!config || !config.apiKey || !config.projectId) {
      return null;
    }

    firebase.initializeApp(config);
    const messaging = firebase.messaging();

    messaging.onBackgroundMessage((payload) => {
      const notification = payload.notification || {};
      const data = payload.data || {};
      const title = notification.title || data.title || 'MIANE';
      const options = {
        body: notification.body || data.body || '',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        data,
      };

      self.registration.showNotification(title, options);
    });

    return messaging;
  })
  .catch((error) => {
    console.warn('[firebase-messaging-sw] Firebase config unavailable.', error);
    return null;
  });

self.addEventListener('push', (event) => {
  event.waitUntil(messagingReady);
});
