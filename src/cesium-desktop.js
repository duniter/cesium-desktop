// Rename "require" to avoid conflicts with pure JS libraries
requireNodejs = require;
require = undefined;

/**** NODEJS MODULES ****/

const fs = requireNodejs('fs'),
  path = requireNodejs('path'),
  yaml = requireNodejs('js-yaml'),
  bs58 = requireNodejs('bs58'),
  clc = requireNodejs('cli-color'),
  gui = requireNodejs('nw.gui');

Base58 = {
  encode: (bytes) => bs58.encode(new Buffer(bytes)),
  decode: (data) => new Uint8Array(bs58.decode(data))
};

/**** Program ****/
const expectedCurrency = "g1";

const APP_ID = "cesium";
const APP_NAME = "Cesium";
const HAS_SPLASH_SCREEN= true;

const HOME = requireNodejs('os').homedir();
const APP_HOME = path.resolve(HOME, path.join('.config', APP_ID));
const APP_KEYRING = path.resolve(APP_HOME, 'keyring.yml');
const SPLASH_SCREEN_TITLE = APP_NAME + " loading..."; // WARN: must be same inside splash.html
const DUNITER_HOME = path.resolve(HOME, '.config/duniter/duniter_default');
const DUNITER_CONF = path.resolve(DUNITER_HOME, 'conf.json');
const DUNITER_KEYRING = path.resolve(DUNITER_HOME, 'keyring.yml');
const DEFAULT_SETTINGS = {
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
      "host": "g1.data.e-is.pro",
      "port": "443",
      "fallbackNodes": [
        {
          "host": "g1.data.presles.fr",
          "port": 443
        },
        {
          "host": "g1.data.mithril.re",
          "port": 443
        }
      ],
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
  return gui && typeof win.showDevTools === 'function';
}
function isMainWin(win) {
  return win && win.title === APP_NAME && true;
}
function isSplashScreen(win) {
  const title = win && win.title;
  console.debug('[desktop] Current window title: ' + title);
  return (title === SPLASH_SCREEN_TITLE);
}

/**
 * Read process command line args
 *
 * @returns {{debug: boolean, menu: boolean}}
 */
function getArgs() {
  const options = {
    verbose: false,
    menu: false,
    debug: false
  };
  const commands = gui && gui.App && gui.App.argv;
  if (commands && commands.length) {
    for (let i in commands) {
      switch (commands[i]) {
        case "--verbose":
          options.verbose = true;
          break;
        case "--menu":
          options.menu = true;
          break;
        case "--debug":
          options.debug = true && isSdkMode();
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
        if (typeof argument === "object" && argument.stack) {
          process.stdout.write(argument.stack);
        }
        else if (typeof argument === "string") {
          process.stdout.write(argument);
        }
        else {
          process.stdout.write(JSON.stringify(argument));
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

  if (options.verbose) {
    if (options.debug) {
      // SDK enable: not need to redirect debug
    }
    else {
      // Re-routing console log
      consoleToStdout(options);
    }
  }
  else {
    // Re-routing console log
    consoleToStdout(options);
  }
}

function openDebugger(subWin, callback) {
  subWin = subWin || win;
  if (isSdkMode()) {
    try {
      console.info("[desktop] Opening debugger...");
      subWin.showDevTools();
      if (callback) callback();
    }
    catch(err) {
      console.error("[desktop] Cannot open debugger:", err);
    }
  }
  else {
    if (callback) callback();
  }
}

function loadSettings(options) {
  if (options && options.settings) return; // Skip, already filled

  console.debug("[desktop] Getting settings from the local storage...");

  let settingsStr = window.localStorage.getItem('settings');
  options.settings = (settingsStr && JSON.parse(settingsStr));
  const localeId = options.settings && options.settings.locale && options.settings.locale.id;
  options.locale = localeId && localeId.split('-')[0] || options.locale || 'en';
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
  options = options || getArgs();
  if (!options.locale) {
    loadSettings(options);
  }
  const locale = options.locale || 'en';

  console.debug("[desktop] Adding menu...");

  var menuBar = new gui.Menu({ type: 'menubar' });

  // File
  var filemenu = new gui.Menu();
  let quitItem = new gui.MenuItem({
    label: I18N[locale].MENU.QUIT_ITEM,
    click: function() {
      console.info("[desktop] Closing...");
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

          console.info("[desktop] Opening new window, for wallet {"+ pubkey.substr(0,8) +"}...");

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
        click: () => openDebugger()
      });
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
  console.info("[desktop] Preparing settings...");
  options = options || getArgs();

  let settings = options.settings;
  let locale = options.locale || 'en';

  /**** Checking app keyring file ****/
  let keyringRaw, keyring, keyPairOK;
  let pubkey = settings && window.localStorage.getItem('pubkey');
  const rememberMe = (!settings && DEFAULT_SETTINGS.rememberMe) || settings.rememberMe == true;
  const keyringFile = settings && settings.keyringFile || APP_KEYRING;
  if (rememberMe && fs.existsSync(keyringFile)) {
    console.debug("[desktop] Keyring file detected at {" + keyringFile + "}...");

    keyringRaw = fs.readFileSync(keyringFile);
    keyring = yaml.safeLoad(keyringRaw);

    keyPairOK = keyring.pub && keyring.sec && true;
    if (!keyPairOK) {
      console.warn("[desktop] Invalid keyring file: missing 'pub' or 'sec' field! Skipping auto-login.");
      // Store settings
      settings = settings || DEFAULT_SETTINGS;
      if (settings.keyringFile) {
        delete settings.keyringFile;
        window.localStorage.setItem('settings', JSON.stringify(settings));
      }
    } else {
      console.debug("[desktop] Auto-login user on {" + keyring.pub + "}");
      window.localStorage.setItem('pubkey', keyring.pub);
      const keepAuthSession = !settings || (settings.keepAuthIdle == 9999);
      if (keepAuthSession) {
        console.debug("[desktop] Auto-authenticate on account (using keyring file)");
        window.sessionStorage.setItem('seckey', keyring.sec);
      }

      // Store settings
      settings = settings || DEFAULT_SETTINGS;
      if (!settings.keyringFile || settings.keyringFile !== keyringFile) {
        settings.keyringFile = keyringFile;
        window.localStorage.setItem('settings', JSON.stringify(settings));
      }
    }
  } else if (settings && settings.keyringFile) {
    console.warn("[desktop] Unable to found keyring file define in settings. Skipping auto-login");
    // Store settings
    settings = settings || DEFAULT_SETTINGS;
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

    console.debug('[desktop] Checking Duniter node config, at ' + DUNITER_CONF + ':', duniterConf);
    console.debug('[desktop] Checking Duniter node pubkey, at ' + DUNITER_KEYRING+ ':', keyring && keyring.pub);

    const local_host = (duniterConf.ipv4 || duniterConf.ipv6);
    const local_port = duniterConf.port;

    let keyPairOK = pubkey && true;
    if (keyPairOK) {
      console.debug('[desktop] Detected logged account: comparing with the local Duniter node...')
      keyPairOK = pubkey === keyring.pub;
      if (!keyPairOK) {
        console.debug('[desktop] Logged account not same as Duniter node.')
        // Check is need to ask user to use node keyring
        if (settings && settings.askLocalNodeKeyring === false) {
          console.debug("[desktop] Do NOT ask to use local node (user ask to ignore this feature)");
          keyPairOK = true;
        }
      } else {
        console.debug('[desktop] Same account as local node!');

        // Configuration de la clef privée, si autorisé dans les paramètres
        const keepAuthSession = !settings || (settings.keepAuthIdle == 9999);
        if (keepAuthSession) {
          console.debug('[desktop] Storing Node keypair to session storage...');
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

        console.debug('[desktop] Make Cesium works on local node...');

        // Generate settings, on local node (with node's keyring)
        const keepAuthSession = !settings || (settings.keepAuthIdle == 9999);
        settings = settings || DEFAULT_SETTINGS;
        settings.node = {
          "host": local_host,
          "port": local_port
        };
        settings.rememberMe = true;
        settings.useLocalStorage = true;
        if (keepAuthSession) {
          settings.keepAuthIdle = 9999;
        }
        settings.plugins = settings.plugins || DEFAULT_SETTINGS.plugins;
        settings.plugins.es = settings.plugins.es || DEFAULT_SETTINGS.plugins.es;
        if (locale === "fr") {
          settings.plugins.es.defaultCountry = "France";
        }

        // Store settings
        window.localStorage.setItem('settings', JSON.stringify(settings));
        options.settings = settings;

        // Store pubkey and seckey (if allowed)
        window.localStorage.setItem('pubkey', keyring.pub);
        if (keepAuthSession) {
          console.debug('[desktop] Configuring Cesium secret key...');
          window.sessionStorage.setItem('seckey', keyring.sec);
        }
      }

      // Do Not ask again
      else {
        console.debug('[desktop] User not need to connect on local node. Configuring Cesium to remember this choice...');
        settings = settings || DEFAULT_SETTINGS;
        settings.askLocalNodeKeyring = false;
        window.localStorage.setItem('settings', JSON.stringify(settings));
        options.settings = settings;
      }
    }
  }

  console.debug("[desktop] Preparing settings [OK]");
}

function openNewWindow(options, callback) {
  options = {
    title: APP_NAME,
    position: 'center',
    width: 1300,
    height: 800,
    min_width: 750,
    min_height: 400,
    frame: true,
    focus: true,
    ...options
  };
  console.debug("[desktop] Opening window {id: '"+ options.id + "', title: '"+ options.title +"'} ...");
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
    fullscreen: false
  }, callback);
}

function openMainWindow(options, callback) {
  console.info("[desktop] Starting main window...");

  openNewWindow({
    id: APP_ID,
    ...options
  }, callback);
}

function openSecondaryWindow(options, callback) {
  openNewWindow({
    id: APP_ID + "-secondary",
    ...options
  }, callback);
}


/****
 * Main PROCESS
 */
function startApp(options) {
  options = options || getArgs();

  if (options.debug) {
    openDebugger(win);
  }

  try {
    console.info("[desktop] Launching "+ APP_NAME + "...", options);

    loadSettings(options);

    console.info("[desktop] User home:  ", options.home);
    console.info("[desktop] User locale:", options.locale);
    console.info("[desktop] Has splash screen? " + HAS_SPLASH_SCREEN);

    prepareSettings(options);

    // If app was started using the splash screen, launch the main window
    if (HAS_SPLASH_SCREEN === true) {

      openMainWindow(options);

      // Close the splash screen, after 1s
      setTimeout(() => win.close(), 1000);
    }
  }
  catch (err) {
    console.error("[desktop] Error while trying to launch: " + (err && err.message || err || ''), err);

    if (options.debug) {
      // Keep open, if debugger open
    }
    else {
      // If app was started using the splash screen, close it
      if (HAS_SPLASH_SCREEN) {
        // Close the splash screen
        setTimeout(() => win.close());
      }
    }
  }


}

// -- MAIN --

// Get command args
const options = getArgs();
// Init logger
initLogger(options);

// Splash screen: start the app
if (isSplashScreen(win)) {
  console.debug('[desktop] isSplashScreen');
  setTimeout(() => startApp(options), 1000);
}

// Main window
else if (isMainWin(win)) {
  console.debug('[desktop] isMainWin');
  // If App not already start : do it
  if (HAS_SPLASH_SCREEN === false) {
    startApp(options);
  }

  // Else (if started) just open the debugger
  else if (options.debug) {
    openDebugger(win);
  }
}
else {
  console.warn("[desktop] Unknown window title: " + (win && win.title || 'undefined'));
}

