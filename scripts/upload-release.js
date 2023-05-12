"use strict";

const co = require('co');
const fs = require('fs');
const os = require('os');
const path = require('path');
const rp = require('request-promise');

const REPO         = 'duniter/cesium'
const tagName      = process.argv[2]
const filePath     = process.argv[3]
const fileType     = getFileType(filePath)

let GITHUB_TOKEN = process.env.GITHUB_TOKEN;
if (!GITHUB_TOKEN) {
  const tokenFilePath = path.resolve(os.homedir(), '.config/cesium/.github');
  GITHUB_TOKEN = fs.readFileSync(tokenFilePath, 'utf8').replace(/\n/g, '')
}

co(function*() {
  try {
    // Get upload URL
    const release = yield github('/repos/' + REPO + '/releases/tags/' + tagName); // May be a draft
    const filename = path.basename(filePath)
    const upload_url = release.upload_url.replace('{?name,label}', '?' + ['name=' + filename].join('&'));

    // Upload file
    console.info(' - Uploading \'%s\' into %s...', filename, release.tag_name);
    yield githubUpload(upload_url, filePath, fileType);
  } catch (e) {
    console.error(e);
  }
  process.exit(0);
});

function github(url) {
  return co(function*() {
    yield new Promise((resolve) => setTimeout(resolve, 1));
    return yield rp({
      uri: 'https://api.github.com' + url,
      json: true,
      headers: {
        'User-Agent': 'Request-Promise',
        'Authorization': 'token ' + GITHUB_TOKEN,
        'Accept': 'application/vnd.github.v3+json'
      }
    });
  });
}

function githubUpload(upload_url, filePath, type) {
  return co(function*() {
    const stats = fs.statSync(filePath);
    return yield rp({
      method: 'POST',
      body: fs.createReadStream(filePath),
      uri: upload_url,
      headers: {
        'User-Agent': 'Request-Promise',
        'Authorization': 'token ' + GITHUB_TOKEN,
        'Content-type': type,
        'Accept': 'application/json',
        'Content-Length': stats.size
      }
    });
  });
}

function getFileType(filePath) {
  let fileType = 'application/vnd.debian.binary-package' // Default: .deb package
  if (path.extname(filePath) === '.gz') {
    fileType = 'application/gzip'
  }
  if (path.extname(filePath) === '.exe') {
    fileType = 'application/vnd.microsoft.portable-executable'
  }
  return fileType
}
