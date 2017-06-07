// require('nw.gui').Window.get().showDevTools()

/**** NODEJS MODULES ****/

const fs = require('fs')
const path = require('path')
const yaml = require('js-yaml')
const bs58 = require('bs58')

Base58 = {
  encode: (bytes) => bs58.encode(bytes),
  decode: (data) => new Uint8Array(bs58.decode(data))
}

/**** Program ****/

const HOME = require('os').homedir()
const DUNITER_HOME = path.resolve(HOME, '.config/duniter/duniter_default')
const duniterConf = require(path.resolve(DUNITER_HOME, 'conf.json'))
const keyringRaw = fs.readFileSync(path.resolve(DUNITER_HOME, 'keyring.yml'))
const keyring = yaml.safeLoad(keyringRaw)

console.log('home = ', HOME)
console.log('conf = ', duniterConf)
console.log('keyring = ', keyring)

const local_host = duniterConf.ipv4
const local_port = duniterConf.port
const local_sign_pk = Base58.decode(keyring.pub);
const local_sign_sk = Base58.decode(keyring.sec);

const DEFAULT_CESIUM_SETTINGS = {
  "useRelative": false,
  "timeWarningExpire": 2592000,
  "useLocalStorage": true,
  "rememberMe": true,
  "plugins": {
    "es": {
      "enable": true,
      "askEnable": false,
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
  "node": {
    "host": local_host,
    "port": local_port
  },
  "showUDHistory": true
}

let settingsStr = window.localStorage.getItem('CESIUM_SETTINGS');
let dataStr = window.localStorage.getItem('CESIUM_DATA');
let settings = (settingsStr && JSON.parse(settingsStr));
let data = (dataStr && JSON.parse(dataStr));


let keyPairOK = data && data.keypair && data.keypair.signPk && data.keypair.signSk && true;
if (keyPairOK) {
  console.log('Trousseau Cesium déjà configuré, comparaison avec celui du nœud local...')
  data.keypair.signPk.length = local_sign_pk.length;
  data.keypair.signSk.length = local_sign_sk.length;
  keyPairOK = Base58.encode(Array.from(data.keypair.signPk)) === keyring.pub
    && Base58.encode(Array.from(data.keypair.signSk)) === keyring.sec
    && data.pubkey === keyring.pub;
  if (!keyPairOK) {
    console.log('Le trousseau Cesium est différent du trousseau du nœud, imposons celui du nœud.')
    // N.B. : ce comportement devrait être **confirmé** par l'utilisateur via une popup par ex.
  } else {
    console.log('Trousseaux identiques : pas de modification du trousseau Cesium à réaliser.')
  }
}

if (!data
  || !keyPairOK
  || settings.node.host != local_host
  || settings.node.port != local_port) {
  if (confirm('Un nœud Duniter a été détecté sur cet ordinateur, voulez-vous que Cesium s\'y connecte ? (plus sécurisé)')) {
    settings = settings || DEFAULT_CESIUM_SETTINGS;
    data = data || {};
    console.debug('Configuring Cesium...');
    settings.node = {
      "host": local_host,
      "port": local_port
    };
    settings.plugins = {
      "es": {
        "enable": true,
        "askEnable": false,
        "host": "g1.data.duniter.fr",
        "port": "443",
        "notifications": {
          "txSent": true,
          "txReceived": true,
          "certSent": true,
          "certReceived": true
        }
      }
    };
    settings.rememberMe = true;
    data.pubkey = keyring.pub;
    data.keypair = {
      signPk: local_sign_pk,
      signSk: local_sign_sk
    };
    window.localStorage.setItem('CESIUM_SETTINGS', JSON.stringify(settings));
    window.localStorage.setItem('CESIUM_DATA', JSON.stringify(data));
  }
}

// Clean "require" command to avoid conflicts with pure JS libraries
require = undefined
