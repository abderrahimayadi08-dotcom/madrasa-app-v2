const admin = require('firebase-admin');

const STATE_DOC = '_fcm_state/checkpoint';

async function main() {
  if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    console.error('Missing FIREBASE_SERVICE_ACCOUNT env');
    process.exit(1);
  }

  const sa = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  admin.initializeApp({ credential: admin.credential.cert(sa) });
  const db = admin.firestore();

  const stateSnap = await db.doc(STATE_DOC).get();
  const state = stateSnap.exists ? stateSnap.data() : {};
  const lastRun = state?.lastRun || new Date(0).toISOString();
  const sentIds = new Set(state?.sentIds || []);

  const now = new Date().toISOString();
  const requests = await db
    .collection('requests')
    .where('updatedAt', '>=', lastRun)
    .get();

  let newSentIds = [...sentIds];
  let count = 0;

  for (const doc of requests.docs) {
    if (sentIds.has(doc.id)) continue;
    const data = doc.data();
    const createdAt = data.createdAt || '';
    const isNew = createdAt >= lastRun;

    if (isNew) {
      const assignedRole = data.assignedRole;
      const cat = data.category === 'purchase' ? 'شراء' : 'صيانة';
      const title = `طلب ${cat} جديد`;
      const body = `${data.userName || 'عضو'}: ${data.itemName || ''}`;

      if (assignedRole) {
        await sendFCM(assignedRole, title, body, data);
      }

      await sendFCM('general_manager', title, body, data);
      newSentIds.push(doc.id);
      count++;
    } else if (data.status && data.updatedAt && data.updatedAt >= lastRun) {
      const statusLabels = {
        approved: 'تمت الموافقة على طلبك',
        rejected: 'تم رفض طلبك',
        hold: 'طلبك معلق',
        completed: 'تم إنجاز طلبك',
      };
      const title = statusLabels[data.status] || 'تحديث الطلب';
      const body = `${data.itemName || ''}`;
      await sendFCM(`user_${data.userId}`, title, body, data);
      newSentIds.push(doc.id);
      count++;
    }
  }

  if (newSentIds.length > 200) newSentIds = newSentIds.slice(-100);

  await db.doc(STATE_DOC).set({
    lastRun: now,
    sentIds: newSentIds,
  }, { merge: true });

  console.log(`Sent ${count} notifications`);
}

async function sendFCM(topic, title, body, data) {
  const payload = {
    topic,
    data: {
      title,
      body,
      category: data.category || '',
      priority: data.priority || 'medium',
      status: data.status || 'pending',
      sticky: 'true',
    },
  };
  try {
    await admin.messaging().send(payload);
  } catch (e) {
    console.error(`FCM error for topic ${topic}:`, e.message);
  }
}

main().catch((e) => {
  console.error('Fatal:', e);
  process.exit(1);
});
