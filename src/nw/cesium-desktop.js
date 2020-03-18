// Rename "require" to avoid conflicts with pure JS libraries
requireNodejs = require;
require = undefined;

const expectedCurrency = "g1";

/**** NODEJS MODULES ****/

const fs = requireNodejs('fs');
const path = requireNodejs('path');
const yaml = requireNodejs('js-yaml');
const bs58 = requireNodejs('bs58');
const clc = requireNodejs('cli-color');
const gui = requireNodejs('nw.gui');

Base58 = {
  encode: (bytes) => bs58.encode(new Buffer(bytes)),
  decode: (data) => new Uint8Array(bs58.decode(data))
};

/**** Program ****/
const HOME = requireNodejs('os').homedir();
const CESIUM_HOME = path.resolve(HOME, '.config/cesium/');
const CESIUM_KEYRING = path.resolve(CESIUM_HOME, 'keyring.yml');
const DUNITER_HOME = path.resolve(HOME, '.config/duniter/duniter_default');
const DUNITER_CONF = path.resolve(DUNITER_HOME, 'conf.json');
const DUNITER_KEYRING = path.resolve(DUNITER_HOME, 'keyring.yml');
const DEFAULT_CESIUM_SETTINGS = {
  "useRelative": false,
  "timeWarningExpire": 2592000,
  "useLocalStorage": true,
  "rememberMe": true,
  "keepAuthIdle": 600,
  "helptip": {
    "enable": false
  },
  "plugins": {
    "es": {
      "enable": true,
      "askEnable": false,
      "useRemoteStorage": false,
      "host": "g1.data.duniter.fr",
      "port": "443",
      "notifications": {
        "txSent": true,
        "txReceived": true,
        "certSent": true,
        "certReceived": true
      }
    }
  },
  "showUDHistory": true
};
const I18N = {
  "fr": {
    "MENU" : {
      "FILE": "Fichier",
      "QUIT_ITEM": "Quitter",
      "WINDOW": "Fenêtre",
      "NEW_WINDOW": "Nouvelle fenêtre",
      "ACCOUNTS": "Mes portefeuilles",
      "OPEN_ACCOUNT": "Compte ",
      "OPEN_DEBUG_TOOL": "Outils de développement..."
    }
  },
  "en": {
    "MENU" : {
      "FILE": "File",
      "QUIT_ITEM": "Quit",
      "WINDOW": "Window",
      "NEW_WINDOW": "New window",
      "ACCOUNTS": "My wallets",
      "OPEN_ACCOUNT": "Wallet",
      "OPEN_DEBUG_TOOL": "Development tools..."
    }
  }
};

// Current window
const win = gui && gui.Window && gui.Window.get();

function isSdkMode () {
  return gui && (window.navigator.plugins.namedItem('Native Client') !== null) && win.showDevTools;
}
function isMainWin() {
  return win && win.title === "Cesium" && true;
}
function isSplashScreen() {
  return (win && win.title === "");
}

/**
 * Read process command line args
 *
 * @returns {{debug: boolean, menu: boolean}}
 */
function getArgs() {
  const options = {
    debug: false,
    menu: false,
    sdk: isSdkMode()
  };
  const commands = gui && gui.App && gui.App.argv;
  if (commands && commands.length) {
    for (let i in commands) {
      switch (commands[i]) {
        case "--debug":
          options.debug = true;
          break;
        case "--menu":
          options.menu = true;
          break;
      }
    }
  }

  options.home = HOME;
  return options;
}

/**
 * Re-routing console log
 * */
function consoleToStdout(options) {
  const superConsole = {
    log: console.log,
    debug: console.debug,
    info: console.info,
    warn: console.warn,
    error: console.error,
  }
  const printArguments = function(arguments) {
    if (arguments.length > 0) {

      for (let i = 0; i < arguments.length; i++) {

        if (i === 1) process.stdout.write('\t');

        const argument = arguments[i];
        if (typeof argument !== "string") {
          process.stdout.write(JSON.stringify(argument));
        }
        else {
          process.stdout.write(argument);
        }
      }
    }
    process.stdout.write('\n');
  };

  if (options && options.debug) {
    console.debug = function (message) {
      process.stdout.write(clc.green("[DEBUG] "));
      printArguments(arguments);
      superConsole.debug.apply(this, arguments);
    };
    console.log = function(message) {
      process.stdout.write(clc.green("[CONSOLE] "));
      printArguments(arguments);
      superConsole.log.apply(this, arguments);
    }
  }
  console.info = function(message) {
    process.stdout.write(clc.blue("[INFO]  "));
    printArguments(arguments);
    superConsole.info.apply(this, arguments);
  };
  console.warn = function(message) {
    process.stdout.write(clc.yellow("[WARN]  "));
    printArguments(arguments);
    superConsole.warn.apply(this, arguments);
  };
  console.error = function() {
    process.stderr.write(clc.red("[ERROR] "));
    printArguments(arguments);
    superConsole.error.apply(this, arguments);
  };
}


function initLogger(options) {
  options = options || getArgs();

  if (options.debug) {
    if (!options.sdk || options.menu) {
      // Re-routing console log
      consoleToStdout(options);
    }
  }
  else {
    // Re-routing console log
    consoleToStdout(options);
  }
}

function loadSettings(options) {
  if (options && options.settings) return; // Skip, already filled

  let settingsStr = window.localStorage.getItem('settings');
  options.settings = (settingsStr && JSON.parse(settingsStr));
  options.locale = (options.settings && options.settings.locale && options.settings.locale.id).split('-')[0] || options.locale || 'en';
}
/**
 * Add menu bar to a window
 * @param win
 * @param options
 */
function addMenu(subWin, options) {
  if (!subWin) {
    console.error("Required 'subWin' argument");
    return;
  }
  options = options || getArgs();
  if (!options.locale) {
    loadSettings(options);
  }
  const locale = options.locale || 'en';

  console.debug("[splash] Adding menu...");

  var menuBar = new gui.Menu({ type: 'menubar' });

  // File
  var filemenu = new gui.Menu();
  let quitItem = new gui.MenuItem({
    label: I18N[locale].MENU.QUIT_ITEM,
    click: function() {
      console.info("[splash] Closing...");
      gui.App.closeAllWindows();
    },});
  filemenu.append(quitItem);
  menuBar.append(new gui.MenuItem({
    label: I18N[locale].MENU.FILE,
    submenu: filemenu
  }));

  // Window
  {
    const winmenu = new gui.Menu();

    // Window > New window
    let newWinItem = new gui.MenuItem({
      label: I18N[locale].MENU.NEW_WINDOW,
      click: () => openSecondaryWindow(options)
    });
    winmenu.append(newWinItem);

    // Window > Accounts
    {
      const accountMenu = new gui.Menu();

      // Window > Accounts > Wallet xxx
      let openAccountItem = new gui.MenuItem({
        label: I18N[locale].MENU.OPEN_ACCOUNT||'Wallet 1',
        click: function() {

          const pubkey = '38MEAZN68Pz1DTvT3tqgxx4yQP6snJCQhPqEFxbDk4aE'; // TODO: get it from storage ?

          console.info("[splash] Opening new window, for wallet {"+ pubkey.substr(0,8) +"}...");

          openSecondaryWindow({
              id: 'cesium-' + pubkey,
              title: 'Wallet ' + pubkey.substr(0,8)
            },
            function(win){
              win.window.localStorage.setItem('pubkey', pubkey);
            });
        },});
      accountMenu.append(openAccountItem);

      winmenu.append(new gui.MenuItem({
        label: I18N[locale].MENU.ACCOUNTS||'Accounts',
        submenu: accountMenu
      }));
    }

    // Window > Debugger
    if (options.sdk) {
      let debugWinItem = new gui.MenuItem({
        label: I18N[locale].MENU.OPEN_DEBUG_TOOL,
        click: function() {
          console.info("[splash] Opening debugger...");
          win.showDevTools();
        },});
      winmenu.append(debugWinItem);
    }

    menuBar.append(new gui.MenuItem({
      label: I18N[locale].MENU.WINDOW,
      submenu: winmenu
    }));
  }


  // Applying menu
  subWin.menu = menuBar;
}

function prepareSettings(options) {
  options = options || getArgs();
  console.info("[splash] Preparing settings...");

  let settings = options.settings;
  let locale = options.locale || 'en';

  /**** Checking Cesium keyring file ****/
  let keyringRaw, keyring, keyPairOK;
  let pubkey = settings && window.localStorage.getItem('pubkey');
  const rememberMe = (!settings && DEFAULT_CESIUM_SETTINGS.rememberMe) || settings.rememberMe == true;
  const keyringFile = settings && settings.keyringFile || CESIUM_KEYRING;
  if (rememberMe && fs.existsSync(keyringFile)) {
    console.debug("[splash] Keyring file detected at {" + keyringFile + "}...");

    keyringRaw = fs.readFileSync(keyringFile);
    keyring = yaml.safeLoad(keyringRaw);

    keyPairOK = keyring.pub && keyring.sec && true;
    if (!keyPairOK) {
      console.warn("[splash] Invalid keyring file: missing 'pub' or 'sec' field! Skipping auto-login.");
      // Store settings
      settings = settings || DEFAULT_CESIUM_SETTINGS;
      if (settings.keyringFile) {
        delete settings.keyringFile;
        window.localStorage.setItem('settings', JSON.stringify(settings));
      }
    } else {
      console.debug("[splash] Auto-login user on {" + keyring.pub + "}");
      window.localStorage.setItem('pubkey', keyring.pub);
      const keepAuthSession = !settings || (settings.keepAuthIdle == 9999);
      if (keepAuthSession) {
        console.debug("[splash] Auto-authenticate on account (using keyring file)");
        window.sessionStorage.setItem('seckey', keyring.sec);
      }

      // Store settings
      settings = settings || DEFAULT_CESIUM_SETTINGS;
      if (!settings.keyringFile || settings.keyringFile != keyringFile) {
        settings.keyringFile = keyringFile;
        window.localStorage.setItem('settings', JSON.stringify(settings));
      }
    }
  } else if (settings && settings.keyringFile) {
    console.warn("[splash] Unable to found keyring file define in Cesium settings. Skipping auto-login");
    // Store settings
    settings = settings || DEFAULT_CESIUM_SETTINGS;
    if (settings.keyringFile) {
      delete settings.keyringFile;
      window.localStorage.setItem('settings', JSON.stringify(settings));
    }
  }

  /**** Checking Duniter configuration files ****/

  if (!keyPairOK && fs.existsSync(DUNITER_CONF) && fs.existsSync(DUNITER_KEYRING)) {
    const duniterConf = requireNodejs(DUNITER_CONF);
    keyringRaw = fs.readFileSync(DUNITER_KEYRING);
    keyring = yaml.safeLoad(keyringRaw);

    console.debug('[splash] Checking Duniter node config, at ' + DUNITER_CONF + ':', duniterConf);
    console.debug('[splash] Checking Duniter node pubkey, at ' + DUNITER_KEYRING+ ':', keyring.pub);

    const local_host = duniterConf.ipv4 || duniterConf.ipv6;
    const local_port = duniterConf.port;

    let keyPairOK = pubkey && true;
    if (keyPairOK) {
      console.debug('[splash] Detected logged account: comparing with the local Duniter node...')
      keyPairOK = pubkey === keyring.pub;
      if (!keyPairOK) {
        console.debug('[splash] Logged account not same as Duniter node.')
        // Check is need to ask user to use node keyring
        if (settings && settings.askLocalNodeKeyring === false) {
          console.debug("[splash] Do NOT ask to use local node (user ask to ignore this feature)");
          keyPairOK = true;
        }
      } else {
        console.debug('[splash] Same account as local node!');

        // Configuration de la clef privée, si autorisé dans les paramètres
        const keepAuthSession = !settings || (settings.keepAuthIdle == 9999);
        if (keepAuthSession) {
          console.debug('[splash] Storing Node keypair to session storage...');
          window.sessionStorage.setItem('seckey', keyring.sec);
        }
      }
    }
    if (duniterConf.currency === expectedCurrency
      && (!keyPairOK
        || (settings && settings.node &&
          (settings.node.host !== local_host || settings.node.port != local_port))
      )) {

      const confirmationMessage = (options.locale === 'fr') ?
        'Un nœud pour la monnaie ' + expectedCurrency + ' a été détecté sur cet ordinateur, voulez-vous que Cesium s\'y connecte ?' :
        'A node for currency ' + expectedCurrency + ' has been detected on this computer. Do you want Cesium to connect it?';

      if (confirm(confirmationMessage)) {

        console.debug('[splash] Make Cesium works on local node...');

        // Generate settings, on local node (with node's keyring)
        const keepAuthSession = !settings || (settings.keepAuthIdle == 9999);
        settings = settings || DEFAULT_CESIUM_SETTINGS;
        settings.node = {
          "host": local_host,
          "port": local_port
        };
        settings.rememberMe = true;
        settings.useLocalStorage = true;
        if (keepAuthSession) {
          settings.keepAuthIdle = 9999;
        }
        settings.plugins = settings.plugins || DEFAULT_CESIUM_SETTINGS.plugins;
        settings.plugins.es = settings.plugins.es || DEFAULT_CESIUM_SETTINGS.plugins.es;
        if (locale === "fr") {
          settings.plugins.es.defaultCountry = "France";
        }

        // Store settings
        window.localStorage.setItem('settings', JSON.stringify(settings));
        options.settings = settings;

        // Store pubkey and seckey (if allowed)
        window.localStorage.setItem('pubkey', keyring.pub);
        if (keepAuthSession) {
          console.debug('[splash] Configuring Cesium secret key...');
          window.sessionStorage.setItem('seckey', keyring.sec);
        }
      }

      // Do Not ask again
      else {
        console.debug('[splash] User not need to connect on local node. Configuring Cesium to remember this choice...');
        settings = settings || DEFAULT_CESIUM_SETTINGS;
        settings.askLocalNodeKeyring = false;
        window.localStorage.setItem('settings', JSON.stringify(settings));
        options.settings = settings;
      }
    }

  }
}

function openNewWindow(options, callback) {
  options = {
    title: "Cesium",
    position: 'center',
    width: 1300,
    height: 800,
    min_width: 750,
    min_height: 400,
    frame: true,
    focus: true,
    ...options
  };
  console.debug("[splash] Opening window {id: '"+ options.id + "', title: '"+ options.title +"'} ...");
  gui.Window.open('cesium/index.html', {
    id: options.id,
    title: options.title,
    position: options.position,
    width:  options.width,
    height:  options.height,
    min_width:  options.min_width,
    min_height:  options.min_height,
    frame:  options.frame,
    focus:  options.focus,
  }, callback);
}

function openMainWindow(options, callback) {
  options = {
    id: "cesium",
    ...options
  };
  openNewWindow({
    id: "cesium",
    ...options
  }, callback);
}

function openSecondaryWindow(options, callback) {
  openNewWindow({
    id: "cesium-secondary",
    ...options
  }, callback);
}


/****
 * Main PROCESS
 */
function startApp(options) {
  options = options || getArgs();

  if (options.debug && options.sdk) {
    win.showDevTools();
  }

  try {
    console.info("[splash] Launching Cesium...", options);

    loadSettings(options);
    console.info("[splash] User home:  ", options.home);
    console.info("[splash] User locale:", options.locale);

    prepareSettings(options);

    openMainWindow(options);
  }
  catch (err) {
    console.error(err);
  }

  setTimeout(() => win.close(), 500);
}

// -- MAIN --

// Get command args
const options = getArgs();
// Init logger
initLogger(options);

// Splash screen: start the app
if (isSplashScreen()) {
  setTimeout(() => startApp(options), 500);
}

// Main window: add menu
else if (isMainWin()) {

  if (options.menu) {
    addMenu(win, options);
  }
}

