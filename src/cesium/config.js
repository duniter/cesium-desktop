/******
* !! WARNING: This is a generated file !!
*
* PLEASE DO NOT MODIFY DIRECTLY
*
* => Changes should be done on file 'app/config.json'.
******/

angular.module("cesium.config", [])

.constant("csConfig", {
	"cacheTimeMs": 300000,
	"demo": false,
	"readonly": false,
	"fallbackLanguage": "en",
	"rememberMe": true,
	"showUDHistory": true,
	"timeout": 40000,
	"timeWarningExpireMembership": 5184000,
	"timeWarningExpire": 7776000,
	"keepAuthIdle": 600,
	"useLocalStorage": true,
	"useRelative": false,
	"expertMode": false,
	"decimalCount": 2,
	"httpsMode": false,
	"shareBaseUrl": "https://demo.cesium.app/",
	"helptip": {
		"enable": true,
		"installDocUrl": {
			"fr-FR": "https://duniter.fr/wiki/doc/installer/",
			"en": "https://duniter.org/en/wiki/duniter/install/"
		}
	},
	"license": {
		"en": "license/license_g1-en",
		"fr-FR": "license/license_g1-fr-FR",
		"es-ES": "license/license_g1-es-ES",
		"ca": "license/license_g1-ca",
		"eo-EO": "license/license_g1-eo-EO",
		"pt-PT": "license/license_g1-pt-PT",
		"it-IT": "license/license_g1-it-IT",
		"de-DE": "license/license_g1-de-DE"
	},
	"feed": {
		"jsonFeed": {
			"fr-FR": "https://raw.githubusercontent.com/duniter/cesium/master/doc/feed/feed-fr.json",
			"en": "https://raw.githubusercontent.com/duniter/cesium/master/doc/feed/feed-en.json",
			"es": "https://raw.githubusercontent.com/duniter/cesium/master/doc/feed/feed-es.json"
		},
		"maxContentLength": 1300
	},
  "node": {
    "host": "g1.duniter.org",
    "port": 443
  },
	"fallbackNodes": [
		{
			"host": "g1.cgeek.fr",
			"port": 443
		},
		{
			"host": "g1.cloud-libre.eu",
			"port": 443
		},
		{
			"host": "g1.e-is.pro",
			"port": 443
		},
		{
			"host": "g1.mithril.re",
			"port": 443
		},
		{
			"host": "vit.fdn.org",
			"port": 443
		},
		{
			"host": "g1.duniter.org",
			"port": 443
		},
		{
			"host": "g1v1.p2P.legal",
			"port": 443
		}
	],
	"developers": [
		{
			"name": "Benoit Lavenier",
			"pubkey": "38MEAZN68Pz1DTvT3tqgxx4yQP6snJCQhPqEFxbDk4aE"
		}
	],
	"plugins": {
		"es": {
			"enable": true,
			"askEnable": true,
			"useRemoteStorage": true,
			"host": "g1.data.e-is.pro",
			"port": 443,
			"fallbackNodes": [
				{
					"host": "g1.data.presles.fr",
					"port": 443
				},
				{
					"host": "g1.data.le-sou.org",
					"port": 443
				},
				{
					"host": "g1.data.mithril.re",
					"port": 443
				},
				{
					"host": "g1.data.e-is.pro",
					"port": 443
				}
			],
			"notifications": {
				"txSent": true,
				"txReceived": true,
				"certSent": true,
				"certReceived": true
			},
			"defaultCountry": "France"
		}
	},
	"version": "1.7.0-rc2",
	"build": "2023-05-11T16:08:06.033Z",
	"newIssueUrl": "https://git.duniter.org/clients/cesium-grp/cesium/issues/new"
})

;
//# sourceMappingURL=maps/config.js.map