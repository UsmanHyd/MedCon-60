const express = require('express');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');
const cron = require('node-cron');

const app = express();
app.use(bodyParser.json());

admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccountKey.json')),
});

let reminders = []; // In-memory storage

// Endpoint to receive schedule requests from Flutter
app.post('/schedule', (req, res) => {
  const { token, dates, reminderTime } = req.body;
  console.log('Received /schedule:', req.body); // Debug log
  if (!token || !dates || !reminderTime) return res.status(400).send('Missing token, dates, or reminderTime');
  reminders.push({ token, dates, reminderTime });
  res.send('Reminder scheduled');
});

// Cron job runs every minute to check for due reminders
cron.schedule('* * * * *', () => {
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
    // Check if today matches any date in the array and time matches reminderTime
    const nowDateStr = `${now.getFullYear()}-${(now.getMonth()+1).toString().padStart(2, '0')}-${now.getDate().toString().padStart(2, '0')}`;
    const nowTimeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
    if (dates.includes(nowDateStr) && nowTimeStr === reminderTime) {
      // Send push notification
      admin.messaging().send({
        token: token,
        notification: {
          title: '💊 MedCon Reminder',
          body: `This is your scheduled notification for ${nowTimeStr}`,
        },
      }).then(() => {
        console.log(`Notification sent to ${token}`);
      }).catch((err) => {
        console.error('Error sending notification:', err);
      });
      return false; // Remove after sending
    }
    return true;
  });
});

app.listen(3000, () => {
  console.log('🚀 Server running on port 3000');
});