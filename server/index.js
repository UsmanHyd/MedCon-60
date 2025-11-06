const express = require('express');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');
const cron = require('node-cron');
const os = require('os');

const app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true })); // Support URL-encoded bodies

// Robust base64/base64url decoder for query params coming from apps like WhatsApp
function decodeQueryBase64(param) {
  if (typeof param !== 'string') return null;
  try {
    // Trim and decode any percent-encoding
    let s = param.trim();
    try { s = decodeURIComponent(s); } catch (_) {}
    // WhatsApp often turns '+' into space; revert
    s = s.replace(/\s/g, '+');
    // Accept both base64url and standard base64 by normalizing to standard
    s = s.replace(/-/g, '+').replace(/_/g, '/');
    // Fix missing padding
    const pad = s.length % 4;
    if (pad === 2) s += '==';
    else if (pad === 3) s += '=';
    const Buffer = require('buffer').Buffer;
    return Buffer.from(s, 'base64').toString('utf8');
  } catch (e) {
    return null;
  }
}

// Initialize Firebase Admin with either GOOGLE_APPLICATION_CREDENTIALS or local JSON
const credential = process.env.GOOGLE_APPLICATION_CREDENTIALS
  ? admin.credential.applicationDefault()
  : admin.credential.cert(require('./serviceAccountKey.json'));
admin.initializeApp({ credential });

function getLocalIp() {
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name] || []) {
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return '127.0.0.1';
}

let reminders = []; // In-memory storage

// Endpoint to receive schedule requests from Flutter
app.post('/schedule', async (req, res) => {
  try {
    const { token, dates, reminderTime } = req.body;
    console.log('Received /schedule:', req.body); // Debug log
    if (!token || !dates || !reminderTime) return res.status(400).send('Missing token, dates, or reminderTime');

    // Immediate send if already due (5 min grace) and date matches today
    const now = new Date();
    const todayStr = `${now.getFullYear()}-${(now.getMonth()+1).toString().padStart(2, '0')}-${now.getDate().toString().padStart(2, '0')}`;
    const [hh, mm] = reminderTime.split(':').map((x) => parseInt(x, 10));
    const scheduled = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hh, mm, 0, 0);
    const dueNow = dates.includes(todayStr) && now >= scheduled && (now.getTime() - scheduled.getTime()) <= 5 * 60 * 1000;

    if (dueNow) {
      console.log('Sending immediately (due on arrival)');
      try {
        await admin.messaging().send({
          token,
          notification: {
            title: '💊 MedCon Reminder',
            body: `This is your scheduled notification for ${hh.toString().padStart(2, '0')}:${mm.toString().padStart(2, '0')}`,
          },
        });
        console.log(`Notification sent immediately to ${token}`);
      } catch (err) {
        console.error('Error sending immediate notification:', err);
      }
      return res.send('Reminder sent immediately');
    }

    // Otherwise queue for cron
    reminders.push({ token, dates, reminderTime });
    return res.send('Reminder scheduled');
  } catch (e) {
    console.error('Schedule error:', e);
    return res.status(500).send('Internal error');
  }
});

// Cron job runs every minute to check for due reminders and SOS alerts
cron.schedule('* * * * *', async () => {
  const now = new Date();
  console.log('--- CRON RUN ---');
  console.log('Server time:', now.toString());
  if (reminders.length === 0) {
    console.log('No reminders scheduled.');
  } else {
    reminders.forEach(({ token, dates, reminderTime }, idx) => {
      console.log(`Reminder #${idx + 1}:`, `Dates: ${dates.join(', ')}`, '| ReminderTime:', reminderTime, '| Token:', token.slice(0, 10) + '...');
    });
  }
  reminders = reminders.filter(({ token, dates, reminderTime }) => {
    // Accept slight delays and send if we've passed the scheduled minute but still the same day
    const nowDateStr = `${now.getFullYear()}-${(now.getMonth()+1).toString().padStart(2, '0')}-${now.getDate().toString().padStart(2, '0')}`;
    const [hh, mm] = reminderTime.split(':').map((x) => parseInt(x, 10));
    const scheduled = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hh, mm, 0, 0);

    const shouldSend = dates.includes(nowDateStr) && now >= scheduled && (now.getTime() - scheduled.getTime()) <= 5 * 60 * 1000; // 5 min grace

    if (shouldSend) {
      admin.messaging()
        .send({
          token,
          notification: {
            title: '💊 MedCon Reminder',
            body: `This is your scheduled notification for ${hh.toString().padStart(2, '0')}:${mm.toString().padStart(2, '0')}`,
          },
        })
        .then(() => {
          console.log(`Notification sent to ${token}`);
        })
        .catch((err) => {
          console.error('Error sending notification:', err);
        });
      return false; // Remove after sending
    }
    return true;
  });
  
  // Check for SOS alerts that need calls (runs every minute)
  await checkAndCallSOSAlerts(now);
});

// Function to check SOS alerts and mark contacts for calling if needed
async function checkAndCallSOSAlerts(now) {
  try {
    const db = admin.firestore();
    // Get all active SOS alerts where call time has passed
    const sosAlerts = await db.collection('sosAlerts')
      .where('status', '==', 'active')
      .get();
    
    if (sosAlerts.empty) {
      return; // No active alerts
    }
    
    console.log(`📞 Checking ${sosAlerts.size} active SOS alerts for due calls...`);
    
    for (const alertDoc of sosAlerts.docs) {
      const data = alertDoc.data();
      const callScheduledAt = data?.callScheduledAt;
      const contacts = data?.contacts || {};
      
      if (!callScheduledAt) continue;
      
      const callTime = new Date(callScheduledAt);
      const nowTime = new Date(now);
      
      // If call time has passed (with 65 second tolerance)
      if (nowTime >= callTime && (nowTime.getTime() - callTime.getTime()) <= 65 * 1000) {
        console.log(`⏰ Call time reached for SOS: ${alertDoc.id}`);
        
        // Check each contact and mark for calling if not confirmed
        for (const [contactIndex, contactData] of Object.entries(contacts)) {
          const status = contactData?.status;
          const phone = contactData?.phone;
          const name = contactData?.name || 'Unknown';
          
          // Only mark as 'callPending' if status is still 'sent' (not confirmed or already called)
          if (status === 'sent' && phone) {
            console.log(`📞 Marking ${name} (${phone}) as ready to call (contact ${contactIndex})`);
            
            // Update status to 'callPending' in Firestore - app will check and initiate call
            await alertDoc.ref.update({
              [`contacts.${contactIndex}.status`]: 'callPending',
              [`contacts.${contactIndex}.callPendingAt`]: admin.firestore.FieldValue.serverTimestamp(),
            });
            
            console.log(`✅ Marked ${name} as callPending in Firestore`);
          }
        }
      }
    }
  } catch (e) {
    console.error('Error checking SOS alerts:', e);
  }
}

// Helper function to handle SOS confirmation
async function handleSOSConfirmation(sosId, contactIndex, res) {
  try {
    console.log('📝 Attempting to confirm SOS:', sosId, 'contact:', contactIndex);
    const cleanSosId = String(sosId)
      .replace(/&/g, '-')
      .replace(/\+/g, '-')
      .replace(/=/g, '-')
      .replace(/%/g, '-')
      .replace(/#/g, '-')
      .replace(/\?/g, '-');

    const db = admin.firestore();
    let docRef = db.collection('sosAlerts').doc(cleanSosId);
    let doc = await docRef.get();

    if (!doc.exists) {
      const exact = await db.collection('sosAlerts').where('sosId', '==', cleanSosId).limit(1).get();
      if (!exact.empty) {
        doc = exact.docs[0];
        docRef = db.collection('sosAlerts').doc(doc.id);
      }
    }

    if (!doc.exists) {
      const recent = await db.collection('sosAlerts').orderBy('timestamp', 'desc').limit(50).get();
      const target = String(cleanSosId).toLowerCase();
      for (const d of recent.docs) {
        const idLow = d.id.toLowerCase();
        const field = (d.data().sosId || d.id).toString().toLowerCase();
        if (idLow === target || field === target) { doc = d; docRef = db.collection('sosAlerts').doc(d.id); break; }
      }
    }

    if (!doc.exists) {
      // Avoid composite index by not mixing where+orderBy; filter in memory
      const recentActiveSnap = await db.collection('sosAlerts')
        .orderBy('timestamp', 'desc')
        .limit(50)
        .get();
      const recentActive = recentActiveSnap.docs.filter((d) => (d.data().status === 'active'));
      for (const d of recentActive) {
        const contacts = d.data().contacts || {};
        if (Object.prototype.hasOwnProperty.call(contacts, String(contactIndex))) {
          doc = d; docRef = db.collection('sosAlerts').doc(d.id); break;
        }
      }
    }

    if (!doc.exists) return res.status(404).send('SOS Alert Not Found');

    await docRef.update({
      [`contacts.${contactIndex}.status`]: 'confirmed',
      [`contacts.${contactIndex}.confirmedAt`]: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log('✅ SOS alert', docRef.id, 'confirmed by contact', contactIndex);
    return res.send(`
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>MedCon SOS - Confirmed</title>
    <style>
      body { font-family: Arial, Helvetica, sans-serif; background:#f5f7f9; margin:0; }
      .container { max-width: 640px; margin: 40px auto; padding: 24px; }
      .card { background:#fff; border-radius:16px; box-shadow:0 10px 25px rgba(0,0,0,.08); padding:40px 32px; text-align:center; }
      .icon { font-size:64px; line-height:1; }
      .ok { color:#16a34a; }
      .title { margin:16px 0 8px; font-size:32px; font-weight:800; letter-spacing:.3px; color:#16a34a; }
      .subtitle { margin:0 0 16px; font-size:16px; color:#475569; }
      .hint { margin-top:28px; font-size:12px; color:#94a3b8; }
      .brand { margin-top:18px; font-size:12px; color:#64748b; }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="card">
        <div class="icon ok">✅</div>
        <div class="title">CONFIRMED</div>
        <div class="subtitle">Thank you. The emergency alert has been acknowledged.</div>
        <div class="hint">You can safely close this page now.</div>
        <div class="brand">MedCon Emergency System</div>
      </div>
    </div>
  </body>
</html>
    `);
  } catch (e) {
    console.error('Error in handleSOSConfirmation:', e);
    return res.status(500).send('Internal error');
  }
}

// SOS Confirmation endpoint - Path-based format (MORE RELIABLE with WhatsApp)
// Format: /sos/confirm/:sosId/:contactIndex
app.get('/sos/confirm/:sosId/:contactIndex', async (req, res) => {
  try {
    // Decode URL-encoded parameters (handles %26 for &, etc.)
    // Express automatically decodes path params, but we need to handle special cases
    let sosId = req.params.sosId;
    let contactIndex = req.params.contactIndex;
    
    // Decode multiple times if needed (handles double-encoding)
    try {
      let decodedSosId = decodeURIComponent(sosId);
      while (decodedSosId !== sosId && decodedSosId.includes('%')) {
        sosId = decodedSosId;
        decodedSosId = decodeURIComponent(sosId);
      }
      sosId = decodedSosId;
    } catch (e) {
      console.log('   Using sosId as-is (decode failed)');
    }
    
    try {
      let decodedIndex = decodeURIComponent(contactIndex);
      while (decodedIndex !== contactIndex && decodedIndex.includes('%')) {
        contactIndex = decodedIndex;
        decodedIndex = decodeURIComponent(contactIndex);
      }
      contactIndex = decodedIndex;
    } catch (e) {
      console.log('   Using contactIndex as-is (decode failed)');
    }
    
    console.log('📥 SOS Confirmation Request (Path-based):');
    console.log('   Raw params:', req.params);
    console.log('   Decoded sosId:', sosId);
    console.log('   Decoded contactIndex:', contactIndex);
    
    if (!sosId || !contactIndex) {
      return res.status(400).send(`
        <html>
          <head>
            <title>Error</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
          </head>
          <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
            <h1 style="color: red;">❌ Error</h1>
            <p>Missing parameters</p>
          </body>
        </html>
      `);
    }
    
    return await handleSOSConfirmation(sosId, contactIndex, res);
  } catch (e) {
    console.error('SOS confirmation error:', e);
    res.status(500).send(`
      <html>
        <head>
          <title>Error</title>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
          <h1 style="color: red;">❌ Error</h1>
          <p>Error: ${e.message}</p>
        </body>
      </html>
    `);
  }
});

// Query parameter format - supports both old format (sosId/contactIndex) and new base64 format (id/idx)
app.get('/sos/confirm', async (req, res) => {
  try {
    console.log('📥 SOS Confirmation Request (Query-based):');
    console.log('   Query:', req.query);
    console.log('   Full URL:', req.url);
    
    let sosId = null;
    let contactIndex = null;
    
    // Try new base64 format first (id/idx) - more reliable
  if (req.query.id && req.query.idx) {
      // Try robust base64/base64url decoding with normalization
      const decodedId = decodeQueryBase64(String(req.query.id));
      const decodedIdx = decodeQueryBase64(String(req.query.idx));
      if (decodedId != null && decodedIdx != null) {
        sosId = decodedId;
        contactIndex = decodedIdx;
        console.log('   ✅ Decoded from base64: id -> sosId, idx -> contactIndex');
      } else {
        console.error('   ❌ Failed to decode base64 params (after normalization)');
      }
    }
    
    // Fallback to old format (sosId/contactIndex) for backward compatibility
    if (!sosId || !contactIndex) {
      sosId = req.query.sosId || req.query.sosld || req.query['sosId'] || req.query['sosld'];
      contactIndex = req.query.contactIndex || req.query['contactIndex'] || req.query.contactIdx || req.query.idx;
      
      // Decode if needed (handle multiple encoding layers)
      if (typeof sosId === 'string') {
        // Also allow base64/base64url in old param
        const maybeBase64 = decodeQueryBase64(sosId);
        if (maybeBase64 != null) {
          sosId = maybeBase64;
        } else {
          try {
            let decoded = decodeURIComponent(sosId.trim());
            while (decoded !== sosId && decoded.includes('%')) {
              sosId = decoded;
              decoded = decodeURIComponent(sosId);
            }
            sosId = decoded;
          } catch (e) {
            console.log('   Using sosId as-is (decode failed)');
            sosId = sosId.trim();
          }
        }
      }
      
      if (typeof contactIndex === 'string') {
        const maybeBase64 = decodeQueryBase64(contactIndex);
        if (maybeBase64 != null) {
          contactIndex = maybeBase64;
        } else {
          try {
            let decoded = decodeURIComponent(contactIndex.trim());
            while (decoded !== contactIndex && decoded.includes('%')) {
              contactIndex = decoded;
              decoded = decodeURIComponent(contactIndex);
            }
            contactIndex = decoded;
          } catch (e) {
            console.log('   Using contactIndex as-is (decode failed)');
            contactIndex = contactIndex.trim();
          }
        }
      }
    }
    
    if (!sosId || !contactIndex) {
      console.error('❌ Query params missing');
      console.error('   Received query keys:', Object.keys(req.query));
      console.error('   sosId:', sosId);
      console.error('   contactIndex:', contactIndex);
      return res.status(400).send(`
        <html>
          <head>
            <title>Error</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
          </head>
          <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px; background-color: #f5f5f5;">
            <div style="background: white; padding: 30px; border-radius: 10px; max-width: 500px; margin: 0 auto;">
              <h1 style="color: red;">❌ Error</h1>
              <p>Missing sosId or contactIndex</p>
              <p style="color: #666; font-size: 12px; margin-top: 20px;">Please use the complete link from WhatsApp message.</p>
              <p style="color: #999; font-size: 10px; margin-top: 10px;">URL received: ${req.url.substring(0, 100)}...</p>
            </div>
          </body>
        </html>
      `);
    }
    
    console.log('   Final - sosId:', sosId, 'contactIndex:', contactIndex);
    
    return await handleSOSConfirmation(sosId, contactIndex, res);
  } catch (e) {
    console.error('SOS confirmation error:', e);
    res.status(500).send(`
      <html>
        <head>
          <title>Error</title>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px; background-color: #f5f5f5;">
          <div style="background: white; padding: 30px; border-radius: 10px; max-width: 500px; margin: 0 auto;">
            <h1 style="color: red;">❌ Error</h1>
            <p style="color: #666;">An error occurred: ${e.message}</p>
            <p style="color: #999; font-size: 12px; margin-top: 20px;">Please try again or contact support.</p>
          </div>
        </body>
      </html>
    `);
  }
});

app.listen(3000, '0.0.0.0', () => {
  const ip = getLocalIp();
  console.log('🚀 Server running on port 3000');
  console.log('📡 Server IP Address:', ip);
  console.log('🌐 Server URL: http://' + ip + ':3000');
  console.log('📱 For Flutter app, update api_config.dart with this IP');
  console.log('');
  console.log('⚠️  IMPORTANT: For confirmation links to work:');
  console.log('   1. Recipient must be on the SAME Wi-Fi network');
  console.log('   2. OR use ngrok: ngrok http 3000');
  console.log('   3. OR deploy to Firebase Cloud Functions');
  console.log('');
});
