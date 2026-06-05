# Deploy the LoveLink Signaling Server

The signaling server is a tiny Node.js app in `signaling_server/`. It must be publicly accessible on the internet so both phones (Bangladesh & Australia) can connect.

## Option 1: Railway.app (Recommended — Free & Fast)

1. Go to https://railway.app and sign up with GitHub
2. Click **New Project → Deploy from GitHub repo**
3. Connect this repo, select the `signaling_server/` subfolder (or set Root Directory to `signaling_server`)
4. Railway auto-detects Node.js and deploys it
5. Click **Settings → Domains → Generate Domain**
6. You get a URL like: `https://lovelink-production.railway.app`
7. Open the app on your phone → enter that URL as the server

**Cost: Free** (500 execution hours/month, enough for full-time use between 2 people)

## Option 2: Render.com (Free — but sleeps after 15 min idle)

1. Go to https://render.com
2. New Web Service → connect GitHub
3. Select `signaling_server/` folder
4. Build command: `npm install`
5. Start command: `node server.js`
6. Free tier: the server sleeps after 15 minutes of inactivity
   - First call after idle takes ~30 seconds to wake up
7. Get URL: `https://lovelink.onrender.com`

## Option 3: Test locally with ngrok (No hosting needed)

Good for testing before setting up cloud hosting.

1. Install ngrok: https://ngrok.com/download
2. Open a terminal: `cd signaling_server && npm install && npm start`
3. Open another terminal: `ngrok http 3000`
4. Get temporary URL like: `https://abc123.ngrok-free.app`
5. Enter that URL in the app
6. **Note**: URL changes every time you restart ngrok (free tier)

---

## After deploying, update the app:

1. Install the APK on both phones
2. On first launch, the app asks for the **Server URL** — enter your Railway/Render URL
3. Select who you are (User 1 or User 2)
4. Done! Both phones connect and you can call each other
