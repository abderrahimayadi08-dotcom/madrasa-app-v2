const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.onRequestCreated = functions.firestore
    .document('requests/{requestId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        const assignedRole = data.assignedRole;

        const usersSnapshot = await admin.firestore()
            .collection('users')
            .where('role', '==', assignedRole)
            .get();

        const tokens = [];
        usersSnapshot.forEach(doc => {
            const token = doc.data().fcmToken;
            if (token) tokens.push(token);
        });

        if (tokens.length === 0) return;

        const title = data.category === 'purchase' ? 'طلب شراء جديد' : 'طلب صيانة جديد';
        const body = `${data.userName}: ${data.itemName}`;

        const message = {
            notification: { title, body },
            tokens: tokens,
        };

        try {
            await admin.messaging().sendEachForMulticast(message);
        } catch (e) {
            console.error('FCM error:', e);
        }
    });
