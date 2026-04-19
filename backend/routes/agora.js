const express = require('express');
const router = express.Router();
const { RtcTokenBuilder, RtcRole } = require('agora-token');

// ❗ ใส่ของคุณตรงนี้
const AGORA_APP_ID = '9e9e8c9e62ad4a2fb7fe0feea3448088';
const AGORA_APP_CERTIFICATE = 'b00c356b7dcf4bea883e23708f8c6ba6';

router.get('/agora/voice-token', async (req, res) => {
  try {
    const channelName = req.query.channelName;
    const uid = Number(req.query.uid || 0);

    if (!channelName) {
      return res.status(400).json({ message: 'channelName is required' });
    }

    const role = RtcRole.PUBLISHER;
    const expireTime = 3600;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expireTime;

    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      uid,
      role,
      privilegeExpiredTs
    );

    res.json({
      appId: AGORA_APP_ID,
      channelName,
      uid,
      token,
    });
  } catch (error) {
    console.error('Agora token error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;