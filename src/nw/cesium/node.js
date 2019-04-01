// Rename "require" to avoid conflicts with pure JS libraries
requireNodejs = require
require = undefined

const expectedCurrency = "g1"

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
}

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
      "NEW_WINDOW_ITEM": "Nouvelle fenêtre"
    }
  },
  "en": {
    "MENU" : {
      "FILE": "File",
      "QUIT_ITEM": "Quit",
      "WINDOW": "Window",
      "NEW_WINDOW_ITEM": "New window"
    }
  }
};

function isSdkMode () {
  return gui && (window.navigator.plugins.namedItem('Native Client') !== null);
}
function isMainWin() {
  return gui && gui.Window.get().title && true;
}

/**** Process command line args ****/
var commands = gui && gui.App && gui.App.argv;
var options = {
  debug: false,
  menu: false
};
if (commands && commands.length) {
  for (i in commands) {
    switch (commands[i]) {
      case "--debug":
        options.debug = true;

        // Open the DEV tool (need a SDK version of NW)
        if (isSdkMode() /*&& isMainWin()*/) {
          gui.Window.get().showDevTools();
        }
        break;
      case "--menu":
        options.menu = true;

        break;
    }
  }
}

/**** Re-routing console log ****/
if (!isSdkMode() || !options.debug) {
  var oldConsole = {
    log: console.log,
    debug: console.debug,
    info: console.info,
    warn: console.warn,
    error: console.error,
  }
  if (debug) {
    console.debug = function (message) {
      process.stdout.write(clc.green("[DEBUG] ") + message + "\n");
      oldConsole.debug.apply(this, arguments);
    };
    console.log = function(message) {
      process.stdout.write(clc.blue("[CONSOLE] ") + message + "\n");
      oldConsole.log.apply(this, arguments);
    }
  }
  console.info = function(message) {
    process.stdout.write(clc.blue("[INFO]  ") + message + "\n");
    oldConsole.info.apply(this, arguments);
  };
  console.warn = function(message) {
    process.stdout.write(clc.yellow("[WARN]  ") + message + "\n");
    oldConsole.warn.apply(this, arguments);
  };
  console.error = function(message) {
    if (typeof message == "object") {
      process.stderr.write(clc.red("[ERROR] ") + JSON.stringify(message) + "\n");
    }
    else {
      process.stderr.write(clc.red("[ERROR] ") + message + "\n");
    }
    oldConsole.error.apply(this, arguments);
  };
}



/**** Starting (main win) ****/

if (isMainWin()) {
  //const nww = requireNodejs('nw');
  let settingsStr = window.localStorage.getItem('settings');
  let settings = (settingsStr && JSON.parse(settingsStr));
  const locale = (settings && settings.locale && settings.locale.id).split('-')[0] || 'en';
  console.debug("[NW] User home {" + HOME + "}");
  console.debug("[NW] Using locale {" + locale + "}");
  if (options.debug) console.info("[NW] Enabling debug mode (--debug)");
  if (options.menu) console.info("[NW] Enabling menu bar(--menu)");

  /**** Menu bar ****/
  if (options.menu) {
    var menuBar = new gui.Menu({ type: 'menubar' });

    // File
    var filemenu = new gui.Menu();
    let quitItem = new gui.MenuItem({
      label: I18N[locale].MENU.QUIT_ITEM,
      click: function() {
        console.log("[NW] Closing...");
        gui.App.closeAllWindows();
      },});
    filemenu.append(quitItem);
    menuBar.append(new gui.MenuItem({
      label: I18N[locale].MENU.FILE,
      submenu: filemenu
    }));

    // Window
    var winmenu = new gui.Menu();
    let newWinItem = new gui.MenuItem({
      label: I18N[locale].MENU.NEW_WINDOW_ITEM,
      click: function() {
        console.log("[NW] Opening new window...");
        gui.Window.open("cesium/debug.html");
      },});
    winmenu.append(newWinItem);


    // Window > Accounts
    var accountMenu = new gui.Menu();
    let openAccountItem = new gui.MenuItem({
      label: I18N[locale].MENU.OPEN_ACCOUNT||'Wallet 1',
      click: function() {
        console.log("[NW] Opening wallet 1...");
        gui.Window.open("cesium/debug.html", {
            focus: true
          },
          function(win){
            win.window.localStorage.setItem('pubkey', "38MEAZN68Pz1DTvT3tqgxx4yQP6snJCQhPqEFxbDk4aE");
            console.log("[NW] Loading wallet 1...");
          });
      },});
    accountMenu.append(openAccountItem);
    winmenu.append(new gui.MenuItem({
      label: I18N[locale].MENU.ACCOUNTS||'Accounts',
      submenu: accountMenu
    }));

    menuBar.append(new gui.MenuItem({
      label: I18N[locale].MENU.WINDOW,
      submenu: winmenu
    }));

    gui.Window.get().menu = menuBar;
  }


  /**** Checking Cesium keyring file ****/
  let keyringRaw, keyring, keyPairOK;
  let pubkey = settings && window.localStorage.getItem('pubkey');
  var rememberMe = (!settings && DEFAULT_CESIUM_SETTINGS.rememberMe) || settings.rememberMe == true;
  var keyringFile = settings && settings.keyringFile || CESIUM_KEYRING;
  if (rememberMe && fs.existsSync(keyringFile)) {
    console.debug("[NW] Keyring file detected at {" + keyringFile + "}...");

    keyringRaw = fs.readFileSync(keyringFile);
    keyring = yaml.safeLoad(keyringRaw);

    keyPairOK = keyring.pub && keyring.sec && true;
    if (!keyPairOK) {
      console.warn("[NW] Invalid keyring file: missing 'pub' or 'sec' field! Skipping auto-login.");
      // Store settings
      settings = settings || DEFAULT_CESIUM_SETTINGS;
      if (settings.keyringFile) {
        delete settings.keyringFile;
        window.localStorage.setItem('settings', JSON.stringify(settings));
      }
    } else {
      console.debug("[NW] Auto-login user on {" + keyring.pub + "}");
      window.localStorage.setItem('pubkey', keyring.pub);
      const keepAuthSession = !settings || (settings.keepAuthIdle == 9999);
      if (keepAuthSession) {
        console.debug("[NW] Auto-authenticate on account (using keyring file)");
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
    console.warn("[NW] Unable to found keyring file define in Cesium settings. Skipping auto-login");
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

    console.log('Duniter conf = ', duniterConf);
    console.log('Duniter keyring pubkey = ', keyring.pub);

    const local_host = duniterConf.ipv4 || duniterConf.ipv6;
    const local_port = duniterConf.port;

    let keyPairOK = pubkey && true;
    if (keyPairOK) {
      console.log('Compte connecté dans Cesium. Comparaison avec celui du nœud local...')
      keyPairOK = pubkey === keyring.pub;
      if (!keyPairOK) {
        console.log('Le compte Cesium est différent de celui du nœud.')
        // Check is need to ask user to use node keyring
        if (settings && settings.askLocalNodeKeyring === false) {
          console.log("L'utilisateur a demander ultérieurement d'ignorer le basculement sur le nœud local.");
          keyPairOK = true;
        }
      } else {
        console.log('Compte Cesium déjà identique au nœud local.');

        // Configuration de la clef privée, si autorisé dans les paramètres
        const keepAuthSession = !settings || (settings.keepAuthIdle == 9999);
        if (keepAuthSession) {
          console.debug('Configuring Cesium secret key...');
          window.sessionStorage.setItem('seckey', keyring.sec);
        }
      }
    }
    if (duniterConf.currency === expectedCurrency
      && (!keyPairOK
        || (settings && settings.node &&
          (settings.node.host != local_host || settings.node.port != local_port))
      )) {


      const confirmationMessage = (locale === 'fr') ?
        'Un nœud pour la monnaie ' + expectedCurrency + ' a été détecté sur cet ordinateur, voulez-vous que Cesium s\'y connecte ?' :
        'A node for currency ' + expectedCurrency + ' has been detected on this computer. Do you want Cesium to connect it?';

      if (confirm(confirmationMessage)) {

        console.debug('Configuring Cesium on local node...');

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

        // Store pubkey and seckey (if allowed)
        window.localStorage.setItem('pubkey', keyring.pub);
        if (keepAuthSession) {
          console.debug('Configuring Cesium secret key...');
          window.sessionStorage.setItem('seckey', keyring.sec);
        }
      }

      // Do Not ask again
      else {
        console.debug('User not need to connect on local node. Configuring Cesium to remember this choice...');
        settings = settings || DEFAULT_CESIUM_SETTINGS;
        settings.askLocalNodeKeyring = false;
        window.localStorage.setItem('settings', JSON.stringify(settings));
      }
    }

  }


}
