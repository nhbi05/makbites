// 1. Import and initialize Firebase Admin SDK
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json"); 

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 2. Send a notification to a user by userId
async function sendNotificationToUser(userId, title, body) {
  // Fetch user's FCM token from Firestore
  const userDoc = await db.collection('users').doc(userId).get();
  const userData = userDoc.data();
  if (!userData || !userData.fcmToken) {
    console.log('No FCM token found for user:', userId);
    return;
  }

  // Create the message
  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: userData.fcmToken,
  };

  // Send the notification
  try {
    await admin.messaging().send(message);
    console.log('Notification sent to', userId);
  } catch (e) {
    console.error('Error sending notification:', e);
  }
}

// 3. (Optional) Mark all unread notifications as read for a user
async function markAllNotificationsAsRead(userId) {
  const snapshot = await db.collection('notifications')
    .where('userId', '==', userId)
    .where('isRead', '==', false)
    .get();

  if (snapshot.empty) {
    console.log('No unread notifications found for user:', userId);
    return;
  }

  const batch = db.batch();
  snapshot.forEach(doc => {
    batch.update(doc.ref, { isRead: true });
  });

  await batch.commit();
  console.log('All notifications marked as read for', userId);
}

// 4. Example usage
const userId = 'PJa83y6mvIhIbCxdrcvaynJUQbk1'; // <-- UPDATE THIS TO YOUR USER/VENDOR ID

sendNotificationToUser(userId, 'Order Update', 'Your order has been shipped!');
// markAllNotificationsAsRead(userId); // Uncomment to mark all as read