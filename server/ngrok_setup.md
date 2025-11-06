# Setting up ngrok for Public URL

## Quick Setup:

1. **Install ngrok:**
   - Download from: https://ngrok.com/download
   - Or use: `npm install -g ngrok` (if you have Node.js)

2. **Run ngrok:**
   ```bash
   ngrok http 3000
   ```

3. **Copy the public URL:**
   - You'll get a URL like: `https://abc123.ngrok.io`
   - Copy this URL

4. **Update api_config.dart:**
   - Replace `http://192.168.0.108:3000` with `https://abc123.ngrok.io`
   - No port needed for ngrok URLs

## Notes:
- Free ngrok URLs change each time you restart
- For permanent URLs, upgrade to ngrok paid plan
- Make sure your server is running on port 3000

