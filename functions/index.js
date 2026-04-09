const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

/**
 * Triggered when a new alert document is created in the 'alerts' collection.
 * Sends an FCM push notification to all users subscribed to the 'sos_alerts' topic.
 */
exports.sendSOSNotification = onDocumentCreated('alerts/{alertId}', async (event) => {
  const alert = event.data.data();

  const message = {
    notification: {
      title: `🚨 SOS: ${alert.type}`,
      body: `${alert.name} at ${alert.houseName} (${alert.houseNo}) needs immediate help!`,
    },
    android: {
      notification: {
        channelId: 'sos_high_importance_channel',
        priority: 'high',
        sound: 'default',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    data: {
      'latitude': alert.latitude?.toString() || '',
      'longitude': alert.longitude?.toString() || '',
      'senderName': alert.name,
      'type': alert.type,
    },
    topic: 'sos_alerts',
  };

  try {
    const response = await getMessaging().send(message);
    console.log('SOS notification sent:', response);
  } catch (error) {
    console.error('Error sending SOS notification:', error);
  }
});
