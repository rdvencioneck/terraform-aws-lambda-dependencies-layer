import json
from posixpath import split
import subprocess
import boto3
import shutil
import os

s3 = boto3.resource("s3")
lambda_client = boto3.client('lambda')

def handler(event, context):

  if "noOps" in event and event["noOps"] == "true":
    return {
      'statusCode': 200,
      'body': json.dumps("Zip File created and uploaded to S3")
    }

  layer_name = event["layerName"]
  bucket = event["bucket"]
  key_prefix= event["keyPrefix"]
  
  if event["deleteOld"] == "true":
    keep_deleting = True
    while keep_deleting:
      layers = lambda_client.list_layer_versions(LayerName=layer_name)
      for layer in layers["LayerVersions"]:
        lambda_client.delete_layer_version(LayerName=layer_name, VersionNumber=layer["Version"])
        print(f"Version {layer['Version']} deleted.")
      if 'NextMarker' not in layers:
        keep_deleting = False

  dependencies_file = cmd_first_line_output("ls --ignore='*.py'")
  layer_dependencies_folder = "/tmp/layer_deps"
  virtualenv_folder = "/tmp/virtualenv"
  os.environ['PIPENV_CACHE_DIR'] = "/tmp/cache"
  build_command = f"cp Pip* /tmp/ && cd /tmp && pip install pipenv && pipenv install --ignore-pipfile" if "Pipfile" in dependencies_file \
                   else "pip install -r requirements.txt"
  generated_zip = "/tmp/layer"

  # build
  run(f"mkdir {layer_dependencies_folder} && python -m venv {virtualenv_folder}")
  run(f". {virtualenv_folder}/bin/activate && \
       {build_command}")

  # copy only necessary files to the layer
  shutil.copytree(f"{virtualenv_folder}/lib",
                  f"{layer_dependencies_folder}/python/lib")

  # zip
  shutil.make_archive(generated_zip, "zip", layer_dependencies_folder, "python")

  # upload
  s3.Bucket(bucket).upload_file(f'{generated_zip}.zip', f'{key_prefix}{layer_name}.zip')

  return {
      'statusCode': 200,
      'body': json.dumps("Zip File created and uploaded to S3")
  }

def run(cmd):
  subprocess.run(cmd, shell=True, check=True)

def cmd_first_line_output(cmd):
  return subprocess.check_output(cmd, shell=True).decode("utf-8").split("\n")[0]