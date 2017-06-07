"use strict";

const co = require('co');
const fs = require('fs');
const os = require('os');
const path = require('path');
const rp = require('request-promise');

const REPO         = 'duniter/cesium'
const tagName      = process.argv[2]

const GITHUB_TOKEN = fs.readFileSync(path.resolve(os.homedir(), '.config/duniter/.github'), 'utf8').replace(/\n/g, '')

co(function*() {
  try {
    // Get release URL
    let refs
    try {
      refs = yield github('/repos/' + REPO + '/git/refs/tags/')
    } catch (e) {
      if (!(e && e.statusCode == 404)) {
        throw e
      }
    }

    let tag = ""
    for (const ref of refs) {
      if (ref.ref === 'refs/tags/' + tagName) {
        tag = tagName
      }
    }
    // As a result of the command, log the tag
    console.log(tag)

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
