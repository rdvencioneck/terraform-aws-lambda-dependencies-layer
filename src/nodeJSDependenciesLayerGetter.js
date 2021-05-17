'use strict';

const AWS = require('aws-sdk');
const fs = require('fs');
const lambda = new AWS.Lambda();

exports.handler = async (event, context) => {

  return await new Promise(resolve => {
    var params = {
      LayerName: "guaca"
    };
    lambda.listLayerVersions(params, function(err, data) {
      if (err) console.log(err, err.stack); // an error occurred
      else {
        resolve({
          statusCode: 200,
          LayerArn: data.LayerVersions[0].LayerVersionArn.split(":", 7).join(":"),
          LayerVersionArn: data.LayerVersions[0].LayerVersionArn,
          Version: data.LayerVersions[0].Version
        });
      }
    });
  });
};