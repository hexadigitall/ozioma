const { app, BrowserWindow } = require('electron');
const path = require('path');

let mainWindow;

app.whenReady().then(() => {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    show: false, // run offscreen for headless verification
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true,
    },
  });

  mainWindow.loadFile(path.join(__dirname, 'dist', 'index.html'));

  mainWindow.webContents.on('did-finish-load', async () => {
    const title = await mainWindow.getTitle();
    console.log(`[VERIFY SUCCESS] Electron loaded successfully with Title: "${title}"`);
    setTimeout(() => {
      app.quit();
      process.exit(0);
    }, 1500);
  });

  mainWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription) => {
    console.error(`[VERIFY FAILED] Load failed: ${errorCode} - ${errorDescription}`);
    process.exit(1);
  });
});
