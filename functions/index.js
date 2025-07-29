/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onRequest} = require("firebase-functions/v2/https");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendScheduledOrders = onSchedule("every 1 minutes", async (event) => {
  const now = Timestamp.now();
  const ordersRef = getFirestore().collection("orders");
  const snapshot = await ordersRef
      .where("status", "==", "pending")
      .where("scheduledSendTime", "<=", now)
      .get();

  const batch = getFirestore().batch();

  snapshot.forEach((doc) => {
    batch.update(doc.ref, {status: "sent", sentAt: now});
    // Optionally: trigger notification to restaurant here
  });

  await batch.commit();
  console.log(
      "Processed " + snapshot.size + " scheduled orders.",
  );
  return null;
});

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
      batch.update(doc.ref, {status: "sent", sentAt: now});
    });

    await batch.commit();

    res.json({
      success: true,
      message: "Processed " + snapshot.size + " scheduled orders.",
      processedCount: snapshot.size,
    });
  } catch (error) {
    console.error("Error processing orders:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});
