'use strict';

const AWS = require('aws-sdk');
const fs = require('fs');
const path = require('path');
const child_process = require('child_process');
const lambda = new AWS.Lambda();

exports.handler = async (event, context) => {

  const env = Object.assign({}, process.env);
  env.HOME = '/tmp';
  const exec = (cmd, cwd) => child_process.execSync(cmd, { cwd, env, stdio: 'inherit' });

  //reqs
  exec('npm install yazl', '/tmp');
  const yazl = require('/tmp/node_modules/yazl')

  // build
  const dependenciesPath = "/tmp/dep"
  exec(`rm -rf ${dependenciesPath}`);
  exec(`mkdir ${dependenciesPath} && cp package.json ${dependenciesPath}`);
  process.chdir(dependenciesPath);
  exec("npm install");

  //zip
  const generatedZip = "/tmp/deps.zip";
  await new Promise(resolve => {
    const zipfile = new yazl.ZipFile();
    zipfile.outputStream.pipe(fs.createWriteStream(generatedZip)).on("close", resolve);
    for (const absPath of walkSync(dependenciesPath)) {
      const relPath = path.relative(dependenciesPath, absPath);
      zipfile.addFile(absPath, relPath);
    }
    zipfile.end();
  });

  //layer
  return await new Promise(resolve => {
    var params = {
      Content: {
        ZipFile: fs.readFileSync(generatedZip)
      },
      LayerName: 'guaca',
    };
    lambda.publishLayerVersion(params, function(err, data) {
      if (err) console.log(err, err.stack);
      else {
        resolve({
          statusCode: 200,
          LayerArn: data.LayerArn,
          LayerVersionArn: data.LayerVersionArn,
          Version: data.Version
        });
      }
    });
  });
};

function* walkSync(dir) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fpath = path.join(dir, file),
      isDir = fs.statSync(fpath).isDirectory();
    if (isDir) {
      yield* walkSync(fpath);
    } else {
      yield fpath;
    }
  }
}