const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

initializeApp();

// FCM `data` payload values must all be strings.
function stringifyData(payload) {
  const data = {};
  if (payload && typeof payload === "object") {
    for (const [key, value] of Object.entries(payload)) {
      if (value !== null && value !== undefined) data[key] = String(value);
    }
  }
  return data;
}

/**
 * Fires whenever a new document is created in notifications/{notificationId}
 * (written today by BookingRepository — see lib/data/repositories/
 * booking_repository.dart). Reads the recipient's stored FCM token
 * (users/{uid}.fcmToken, written by lib/core/services/fcm_service.dart)
 * and sends a single push using the notification's existing title/body.
 * Mirrors the route-derivation `fcm_service.dart` already does on the
 * client by forwarding `payload` as the FCM `data` map unchanged.
 */
exports.sendNotificationPush = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const notif = snap.data();
    const recipientUid = notif.userId;
    if (!recipientUid) {
      logger.warn("Notification missing userId", { id: event.params.notificationId });
      return;
    }

    const firestore = getFirestore();
    const userDoc = await firestore.collection("users").doc(recipientUid).get();
    const token = userDoc.data()?.fcmToken;
    if (!token) {
      // No device registered for this user — nothing to send, not an error.
      return;
    }

    const message = {
      token,
      notification: {
        title: notif.title || "JeevaMitra",
        body: notif.body || "",
      },
      data: stringifyData(notif.payload),
    };

    try {
      await getMessaging().send(message);
    } catch (err) {
      const invalidTokenCodes = new Set([
        "messaging/invalid-registration-token",
        "messaging/registration-token-not-registered",
        "messaging/invalid-argument",
      ]);
      if (invalidTokenCodes.has(err.code)) {
        // Stale/invalid token — clear it so future notifications don't keep
        // retrying a dead device instead of silently failing every time.
        await firestore
          .collection("users")
          .doc(recipientUid)
          .update({ fcmToken: FieldValue.delete() })
          .catch((clearErr) =>
            logger.error("Failed clearing invalid fcmToken", clearErr));
        return;
      }
      logger.error("sendNotificationPush failed", err);
    }
  }
);

/**
 * Fires whenever a new document is created in disease_alerts/{alertId}
 * (written by lib/data/repositories/disease_alert_repository.dart —
 * createAlert only writes the alert itself; it never queries other users).
 * Runs server-side with Admin SDK privileges (bypasses Firestore rules,
 * which correctly keep `users` documents readable only by their owner) to
 * find every user in the alert's district, excludes the reporter, and
 * writes one notifications/{id} doc per recipient using the exact same
 * schema BookingRepository already writes. It does NOT send FCM itself —
 * each notification doc it creates is picked up by the existing
 * sendNotificationPush trigger above, which stays solely responsible for
 * push delivery.
 */
exports.onDiseaseAlertCreated = onDocumentCreated(
  "disease_alerts/{alertId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const alert = snap.data();
    const alertId = event.params.alertId;
    const district = alert.district;
    if (!district) return;

    const firestore = getFirestore();
    const recipients = await firestore
      .collection("users")
      .where("district", "==", district)
      // Stay well under Firestore's 500-write batch limit.
      .limit(450)
      .get();

    if (recipients.empty) return;

    const batch = firestore.batch();
    const notifCol = firestore.collection("notifications");
    let count = 0;

    for (const userDoc of recipients.docs) {
      if (userDoc.id === alert.reportedBy) continue; // exclude the reporter
      batch.set(notifCol.doc(), {
        userId: userDoc.id,
        type: "disease_alert",
        title: `Disease alert: ${alert.disease || "Unknown"}`,
        body: `${alert.title || "New alert"} — reported in ${district}.`,
        payload: { alertId },
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });
      count++;
    }

    if (count === 0) return;
    await batch.commit();
  }
);
