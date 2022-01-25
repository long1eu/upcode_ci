## 0.8.4

Generate client stubs for node proto

## 0.8.3

Fix version set ignoring the env argument

## 0.8.2

Fix generator not finding the API Key

## 0.8.1

Fix google proto files not being included in generation

## 0.8.0

Add null-safety, let me know if you have any errors, and I'll make sure to fix them ass soon as possible

## 0.7.1

Scrub google fields out of the api descriptor.
See https://gist.github.com/kristiandrucker/d3a7c7b8e64f55ad4ebfa3634a96d5fe
and https://issuetracker.google.com/issues/210014211

## 0.7.0

* Breaking Change: require `grpc_tools_node_protoc_plugin` and `grpc-tools` be globally installed using `npm install -g`

## 0.6.6

* update proto js definition from grpc to grpc-js

## 0.6.5

* skip version in api deploy if we can't read it

## 0.6.4
* allow the use of environment without firebase

## 0.6.3
* respect the deployService flag when deploying all on api

## 0.6.2
* allow setting min instances for cloud run

## 0.6.1
* allow the ability to add multiple images for the api
* allow specifying a list of Cloud SQL instances that you want to link to all images or to just one. If the `cloudsql_instances` is use at the image level the top level values will be ignored
```yaml
api:
  cloudsql_instances:
    - project:region:name
  images:
    - name:
      selector: "*"
    - name: name
      selector: domain.v1.Service.*
      cloudsql_instances:
        - project:region:name01
```

## 0.6.0+1
* throw is we are not able to read the version

## 0.6.0+3
* add analysis options
* update dependencies

## 0.6.0
* allow the user to specify a version incrementation algorithm

## 0.5.1+2
* add cmd to protoc ts tools

## 0.5.1+1
* add cmd to protoc ts compiler

## 0.5.1
* use os path separator on upcode.yaml paths

## 0.5.0
* BREAKING CHANGE: don't increment the version when deploying api, just
  read the current one

## 0.4.7
* allow setting the version back to cloud with version set

## 0.4.6
* allow setting the version type

## 0.4.5+1
* print version when reading it

## 0.4.5
* remove yarn dependency

## 0.4.4
* read database url from google-services.json

## 0.4.3
* don't generate the import files anymore

## 0.4.2
* use an absolute path for modules when iterating over them

## 0.4.1
* update fad to accept a firebase token

## 0.4.0
* add api implementation

## 0.3.6
* add release notes for firebase app distribution

## 0.3.5+1
* normalize flutter module dirname

## 0.3.5
* add option to set a specific version

## 0.3.4
* add support for setting the env in the version name

## 0.3.3
* remove env name restriction

## 0.3.2
* add protobuf generation

## 0.3.1+1
* remove debug flag from firebase app distribution

## 0.3.1
* override configurations base on envs

## 0.3.0
* **Breaking** the way the version is saved in FRDB has changed, now the
  version is saved under the same name as the flutter module
* add ability to specify flutter and private folder when
  invoking any command

## 0.2.5
* add coverage to tests

## 0.2.4
* use system separator

## 0.2.3+1
* add different app id for android and ios
* the environment command doesn't need env anymore, this command will be split up into config and env

## 0.2.3
* add different app id for android and ios
* the environment command doesn't need env anymore, this command will be split up into config and env

## 0.2.2
* pub get before testing

## 0.2.1
* exclude chopper from formatting

## 0.2.0
* remove `formatted_modules` and `analyzed_modules`
* add `formatted`, `analyzed`, `tested` and `generated`

## 0.1.5
* add config based on environment

## 0.1.4+1
* fix `formatted_modules`

## 0.1.4
* add `formatted_modules` and `analyzed_modules`

## 0.1.3
* pub get before running the generator

## 0.1.2
* add `generated_modules`

## 0.1.1+1
* update readme

## 0.1.1
* add executable

## 0.1.0
* initial release