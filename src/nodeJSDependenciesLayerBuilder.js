'use strict';

const AWS = require('aws-sdk');
const lambda = new AWS.Lambda();
const s3 = new AWS.S3();

const fs = require('fs');
const path = require('path');
const childProcess = require('child_process');

exports.handler = async (event, context) => {

  if(event.noOps){
    return {
      statusCode: 200,
      body: "Zip File created and uploaded to S3"
    }
  }

  const layerName = event.layerName;

  if(event.deleteOld){
    lambda.listLayerVersions({LayerName: layerName}, function(err, data) {
      if (err) console.log("Failed to delete Old Versions", err, err.stack); 
      else {
        data.LayerVersions.forEach(function (layer, index) {
          const deleteParams = { LayerName: layerName, VersionNumber: layer.Version };
          lambda.deleteLayerVersion(deleteParams, function(err, data) {
            if (err) console.log(err, err.stack);
            else {
              console.log("Version", layer.Version + "deleted.");
            }
          });
        });
      }
    });
  }
  
  const bucket = event.bucket;
  const keyPrefix = event.keyPrefix;

  // deps
  const env = Object.assign({}, process.env);
  env.HOME = '/tmp';
  const exec = (command, cwd) => childProcess.execSync(command, { cwd, env, stdio: 'inherit' });
  exec('npm install yazl', '/tmp');
  const yazl = require('/tmp/node_modules/yazl');

  // build
  const dependenciesPath = "/tmp/nodejs";
  exec(`rm -rf ${dependenciesPath}`);
  exec(`mkdir ${dependenciesPath} && cp package.json ${dependenciesPath}`);
  exec("npm install", dependenciesPath);
  exec('ls -1 node_modules | awk \'{print "exports."$1" = require(\\"" $1 "\\");"}\' >> index.js', dependenciesPath);
  
  // zip
  const generatedZip = "/tmp/layer.zip";
  await new Promise(resolve => {
    const zipfile = new yazl.ZipFile();
    zipfile.outputStream.pipe(fs.createWriteStream(generatedZip)).on("close", resolve);
    for (const absPath of walkSync(dependenciesPath)) {
      const relPath = "nodejs/" + path.relative(dependenciesPath, absPath);
      zipfile.addFile(absPath, relPath);
    }
    zipfile.end();
  });

  // upload
  await s3.putObject({ Bucket: bucket, Key: keyPrefix + layerName + ".zip", Body: fs.createReadStream(generatedZip) }).promise();
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