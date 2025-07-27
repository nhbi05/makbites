const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Notify restaurant when a new order is created
exports.notifyRestaurantOnNewOrder = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const restaurantId = order.restaurantId; // Adjust field name as needed

    // Get restaurant FCM token
    const restaurantDoc = await admin.firestore().collection('users').doc(restaurantId).get();
    const restaurantData = restaurantDoc.data();
    if (!restaurantData || !restaurantData.fcmToken) return null;

    const message = {
      notification: {
        title: 'New Order Received!',
        body: 'You have a new order from a customer.',
      },
      token: restaurantData.fcmToken,
    };
    await admin.messaging().send(message);
    return null;
  });

// Notify customer when their order status changes
exports.notifyCustomerOnOrderUpdate = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only notify if status actually changed
    if (before.status === after.status) return null;

    const customerId = after.customerId; // Adjust field name as needed
    const customerDoc = await admin.firestore().collection('users').doc(customerId).get();
    const customerData = customerDoc.data();
    if (!customerData || !customerData.fcmToken) return null;

    const message = {
      notification: {
        title: 'Order Update',
        body: `Your order status is now: ${after.status}`,
      },
      token: customerData.fcmToken,
    };
    await admin.messaging().send(message);
    return null;
  });

// Notify delivery driver when assigned a delivery
exports.notifyDriverOnAssignment = functions.firestore
  .document('deliveries/{deliveryId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only notify if driverId was just assigned
    if (before.driverId === after.driverId || !after.driverId) return null;

    const driverDoc = await admin.firestore().collection('users').doc(after.driverId).get();
    const driverData = driverDoc.data();
    if (!driverData || !driverData.fcmToken) return null;

    const message = {
      notification: {
        title: 'New Delivery Assignment',
        body: 'You have been assigned a new delivery.',
      },
      token: driverData.fcmToken,
    };
    await admin.messaging().send(message);
    return null;
  });