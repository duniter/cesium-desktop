// require('nw.gui').Window.get().showDevTools()

// Rename "require" to avoid conflicts with pure JS libraries
requireNodejs = require
require = undefined

const expectedCurrency = "g1"

/**** NODEJS MODULES ****/

const fs = requireNodejs('fs')
const path = requireNodejs('path')
const yaml = requireNodejs('js-yaml')
const bs58 = requireNodejs('bs58')

Base58 = {
  encode: (bytes) => bs58.encode(bytes),
  decode: (data) => new Uint8Array(bs58.decode(data))
}

/**** Program ****/
const HOME = requireNodejs('os').homedir()
const CESIUM_HOME = path.resolve(HOME, '.config/cesium/' + expectedCurrency)
const CESIUM_KEYRING = path.resolve(CESIUM_HOME, 'keyring.yml')
const DUNITER_HOME = path.resolve(HOME, '.config/duniter/duniter_default')
const DUNITER_CONF = path.resolve(DUNITER_HOME, 'conf.json')
const DUNITER_KEYRING = path.resolve(DUNITER_HOME, 'keyring.yml')

let keyringRaw,keyring, keyPairOK;
console.log('User home = ', HOME);

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
let settingsStr = window.localStorage.getItem('settings');
let settings = (settingsStr && JSON.parse(settingsStr));
let pubkey = settings && window.localStorage.getItem('pubkey');


/**** Checking Cesium keyring file ****/

if (fs.existsSync(CESIUM_KEYRING)) {
  keyringRaw = fs.readFileSync(CESIUM_KEYRING);
  keyring = yaml.safeLoad(keyringRaw);

  keyPairOK = !keyring.pub || !keyring.sec;
  if (!keyPairOK) {
    console.log('Invalid Cesium keyring file at ' + CESIUM_KEYRING + '. Skipping.');
  }
  else {
    console.log('Cesium keyring pubkey=', keyring.pub);
    window.localStorage.setItem('pubkey', keyring.pub);
    const keepAuthSession = settings && (settings.keepAuthIdle == 9999);
    if (keepAuthSession) {
      console.debug('Configuring Cesium secret key...');
      window.sessionStorage.setItem('seckey', keyring.sec);
    }
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
    keyPairOK = data.pubkey === keyring.pub;
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

    // Detect locale
    const locale = (settings && settings.locale && settings.locale.id).split('-')[0] || 'en';
    console.debug('Using locale: ' + locale);

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


