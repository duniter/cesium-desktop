"use strict";

const co = require('co');
const fs = require('fs');
const os = require('os');
const path = require('path');
const rp = require('request-promise');

const REPO         = 'duniter/cesium'
const tagName      = process.argv[2]
const command      = process.argv[3]
const value        = process.argv[4]

const GITHUB_TOKEN = fs.readFileSync(path.resolve(os.homedir(), '.config/cesium/.github'), 'utf8').replace(/\n/g, '')

co(function*() {
  try {
    // Get release URL
    let release
    try {
      release = yield github('/repos/' + REPO + '/releases/tags/' + tagName)
    } catch (e) {
      if (!(e && e.statusCode == 404)) {
        throw e
      }
    }

    // Creation
    if (command === "create") {
      if (!release) {
        release = yield github('/repos/' + REPO + '/releases', 'POST', {
          tag_name: tagName.replace(/^v/, ''),
          draft: false,
          prerelease: true
        })
      } else {
        console.error('Release ' + tagName + ' already exists. Skips creation.')
      }
      // As a result of the command, log the already uploaded assets' names
      for (const asset of release.assets) {
        console.log(asset.name)
      }
    }

    // Update to release
    else if (command === "set") {
      const isPreRelease = value != 'rel'
      const status = isPreRelease ? 'pre-release' : 'release'
      if (!release) {
        console.error('Release ' + tagName + ' does not exist.')
      } else {
        release = yield github('/repos/' + REPO + '/releases/' + release.id, 'PATCH', {
          tag_name: tagName,
          draft: false,
          prerelease: isPreRelease
        })
      }
      console.log('Release set to status \'%s\'', status)
    }

    else {
      console.error("Unknown command '%s'", command)
      process.exit(1)
    }

  } catch (e) {
    console.error(e);
  }
  process.exit(0);
});

function github(url, method = 'GET', body = undefined) {
  return co(function*() {
    yield new Promise((resolve) => setTimeout(resolve, 1));
    return yield rp({
      uri: 'https://api.github.com' + url,
      method,
      body,
      json: true,
      headers: {
        'User-Agent': 'Request-Promise',
        'Authorization': 'token ' + GITHUB_TOKEN,
        'Accept': 'application/vnd.github.v3+json'
      }
    });
  });
}
