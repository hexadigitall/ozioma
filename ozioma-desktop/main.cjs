const { app, BrowserWindow, Menu, shell, dialog } = require('electron');
const path = require('path');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1100,
    minHeight: 700,
    title: 'Ozioma — Worldwide Congregation Administration & GIS Power Tool',
    backgroundColor: '#020617', // slate-950
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true,
    },
    icon: path.join(__dirname, 'public/favicon.ico'),
  });

  const isDev = process.env.NODE_ENV === 'development';
  if (isDev) {
    mainWindow.loadURL('http://localhost:1420');
  } else {
    mainWindow.loadFile(path.join(__dirname, 'dist', 'index.html'));
  }

  // Native Windows Desktop Menu Template
  const template = [
    {
      label: '&File',
      submenu: [
        {
          label: 'New Territory Boundary...',
          accelerator: 'CmdOrCtrl+N',
          click: () => {
            mainWindow.webContents.send('menu-action', 'new-territory');
          },
        },
        {
          label: 'Print S-13 Territory Cards...',
          accelerator: 'CmdOrCtrl+P',
          click: () => {
            mainWindow.webContents.send('menu-action', 'print-s13');
          },
        },
        {
          label: 'Import Master Streets (CSV/Excel)...',
          accelerator: 'CmdOrCtrl+I',
          click: () => {
            mainWindow.webContents.send('menu-action', 'import-csv');
          },
        },
        { type: 'separator' },
        { role: 'quit', label: 'Exit Ozioma' },
      ],
    },
    {
      label: '&Edit',
      submenu: [
        { role: 'undo' },
        { role: 'redo' },
        { type: 'separator' },
        { role: 'cut' },
        { role: 'copy' },
        { role: 'paste' },
      ],
    },
    {
      label: '&Territories',
      submenu: [
        {
          label: 'Search Territories...',
          accelerator: 'CmdOrCtrl+F',
          click: () => {
            mainWindow.webContents.send('menu-action', 'focus-search');
          },
        },
        {
          label: 'Split Selected Polygon (#A/#B)...',
          accelerator: 'CmdOrCtrl+S',
          click: () => {
            mainWindow.webContents.send('menu-action', 'split-poly');
          },
        },
        {
          label: 'Snap to Street Vectors',
          click: () => {
            mainWindow.webContents.send('menu-action', 'snap-streets');
          },
        },
      ],
    },
    {
      label: '&Reports',
      submenu: [
        {
          label: 'Circuit Overseer (CO) & Annual S-8 Suite',
          accelerator: 'CmdOrCtrl+R',
          click: () => {
            mainWindow.webContents.send('menu-action', 'co-analytics');
          },
        },
        {
          label: 'Territory Saturation Heatmap',
          click: () => {
            mainWindow.webContents.send('menu-action', 'saturation-heatmap');
          },
        },
      ],
    },
    {
      label: '&View',
      submenu: [
        { role: 'reload' },
        { role: 'forceReload' },
        { role: 'toggleDevTools' },
        { type: 'separator' },
        { role: 'resetZoom' },
        { role: 'zoomIn' },
        { role: 'zoomOut' },
        { type: 'separator' },
        { role: 'togglefullscreen' },
      ],
    },
  ];

  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});
