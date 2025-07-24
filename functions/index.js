const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Scheduled Function: Runs every 1 minute

exports.sendScheduledOrders = onSchedule("every 1 minutes", async (event) => {
  const now = Timestamp.now();
  const ordersRef = getFirestore().collection("orders");
  const snapshot = await ordersRef
    .where("status", "==", "pending")
    .where("scheduledSendTime", "<=", now)
    .get();

  const batch = getFirestore().batch();

  for (const doc of snapshot.docs) {
    const orderData = doc.data();

    batch.update(doc.ref, { status: "sent", sentAt: now });

    const vendorId = orderData.restaurant;
    const vendorDoc = await getFirestore().collection("restaurants").doc(vendorId).get();

    if (vendorDoc.exists) {
      const vendorData = vendorDoc.data();
      const token = vendorData.deviceToken;

      if (token) {
        await admin.messaging().send({
          token,
          notification: {
            title: "New Order Received",
            body: `You have a new order: ${doc.id}`,
          },
          data: {
            orderId: doc.id,
            status: "sent",
          },
        });
        console.log(`✅ Notification sent to vendor ${vendorId}`);
      } else {
        console.log(`⚠️ No deviceToken for vendor ${vendorId}`);
      }
    }
  }

  await batch.commit();
  console.log(`✅ Processed ${snapshot.size} scheduled orders.`);
  return null;
});

/**
 * HTTP Callable Function (manual testing)
 */
exports.testOrderProcessing = onRequest(async (req, res) => {
  try {
    const now = Timestamp.now();
    const ordersRef = getFirestore().collection("orders");
    const snapshot = await ordersRef
      .where("status", "==", "pending")
      .where("scheduledSendTime", "<=", now)
      .get();

    const batch = getFirestore().batch();

    snapshot.forEach((doc) => {
      batch.update(doc.ref, { status: "sent", sentAt: now });
    });

    await batch.commit();

    res.json({
      success: true,
      message: `✅ Processed ${snapshot.size} scheduled orders.`,
      processedCount: snapshot.size,
    });
  } catch (error) {
    console.error("❌ Error processing orders:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Firestore trigger: Notify customer when order status changes
 */
exports.notifyCustomerOnOrderStatusChange = onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const orderId = event.params.orderId;

  console.log(`📦 Order updated: ${orderId}`);
  console.log(`🔁 Status change: ${before.status} ➡️ ${after.status}`);

  if (before.status === after.status) {
    console.log("ℹ️ No status change detected. Skipping notification.");
    return null;
  }

  const userId = after.userId;
  const prepTime = after.preparationTimeMinutes || null;

  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  const deviceToken = userDoc.data()?.deviceToken;

  if (!deviceToken) {
    console.warn(`⚠️ No device token found for user ${userId}`);
    return null;
  }

  let payload;

  if (after.status.toLowerCase() === "start preparing" && prepTime) {
    payload = {
      notification: {
        title: "Order Update",
        body: `Your order will be ready in ${prepTime} minutes.`,
      },
    };
  } else if (after.status.toLowerCase() === "completed") {
    payload = {
      notification: {
        title: "Order Update",
        body: "Your order is on the way.",
      },
    };
  } else {
    console.log("ℹ️ No notification configured for this status.");
    return null;
  }

  try {
    const response = await admin.messaging().sendToDevice(deviceToken, payload);
    console.log("✅ Notification sent successfully:", response);
  } catch (error) {
    console.error("❌ Failed to send notification:", error);
  }

  return null;
});
