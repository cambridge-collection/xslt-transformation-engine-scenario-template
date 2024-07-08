# XSLT Transformation Engine (XTE) Scenario Template

This repository provides a base template for rolling your own implementation of the [Cambridge Digital Collection XSLT Transformation Engine (XTE)](https://github.com/cambridge-collection/xslt-transformation-engine) that can run as:

* an AWS lambda that transforms the file using your XSLT in response to an SQS notification informing it of a file change to source file in your S3 source bucket. The output is deposited in the S3 output bucket defined in the env variable `AWS_OUTPUT_BUCKET`. 
* a standalone build that can be run locally or within a CI/CD system. It acts upon any number of items contained within the `./source` dir. The outputs are copied to `./out`.

## Prerequisites

- Docker [<https://docs.docker.com/get-docker/>]

## Rolling your own transformation scenario

### Basic Instructions

1. Create a copy of this repository for your transformation scenario by either forking it in GitHub or by creating a bare clone. See [To Fork or Not to Fork](#to-fork-or-not-to-fork) to decide which approach might work best for you.
2. Create a new branch in the repository for your work and make it the default branch in GitHub by going to Settings -> General.
3. Copy your XSLT into `./docker/xslt`.
4. Define the `XSLT_ENTRYPOINT` environment variable so that it points to your custom xslt. This variable takes `./docker` as its root. If your custom XSLT were called `my-custom.xsl`, `XSLT_ENTRYPOINT` would be set to `xslt/my-custom.xsl`.
5. Set any other required and optional environment variables that might need changing. See <https://github.com/cambridge-collection/xslt-transformation-engine?tab=readme-ov-file#required-environment-variables-for-both-aws-and-standalone-versions> for a list of all the available variables.
6. Test your container locally by using the docker compose file for your specific environment (_i.e._ `compose-aws-dev.yml` for AWS or `compose-standalone.yml` for standalone) as per the instructions on <https://github.com/cambridge-collection/xslt-transformation-engine>.

### Advanced Transformation Scenarios

The above approach will work for transformation scenarios that involve transforming one (or more) source XML files into output files using XSLT. This is the most common pattern for transforming XML documents. Sometimes, however, more complicated transforms are necessary. For example, your transformation might depend on the presence of certain supplementary source files (_e.g._ various authority files) or you might need to change the directory structure of your output files (_e.g._ flattening the directory hierarchy of the outputs). You can extend your transformation scenario using [preprocessing and post-processing hooks](#preprocessing-and-post-processing-hook-scripts) and/or a [custom build script](#custom-build-scripts). 

### Preprocessing and post-processing hook scripts

XTE provides two hooks for running custom bash scripts:

* the **preprocessing** hook (`pre.sh`) runs immediately before the transformation starts.
* the **post-processing** hook (`post.sh`) runs after the transformation has finished but before the outputs are uploaded to the destination bucket.

To add one (or both) of these hooks into your transformation scenario simply add a shell script called `pre.sh` or `post.sh` into `./docker/`. The easiest way to do this is to copy the relevant script(s) from `./sample-hook-scripts`  into `./docker/` and then add your custom code into the relevant file(s). These scripts already contain some useful features (_e.g._ environment variables) and more will be added in the future.

If you are adding in your own custom hook scripts, be sure to:

1. include `set -euo pipefail` at the start of the file. This ensures that the failure of any command within the script will cause the script to return an unsuccessful result code. Otherwise, it’s possible that some component in your pipeline might fail but the script itself reports that it was successfully run. This line is included in the sample scripts.
2. `$1` in both scripts contain a special value. In `pre.sh` `$1` contains the path to the directory containing your source file. It is mapped onto the `SOURCE_DIR` environment variable in the sample `pre.sh` script. In `post.sh` `$1` contains the path to the local directory in the docker container that contains the outputs of your transformation. It is mapped onto the `DIST_PENDING_DIR` environment variable in the sample `post.sh` script.

**Note:** If you are running your container within AWS, only `STDERR` will appear in your logs. If you want `STDOUT` to appear, you will have to redirect it to `STDERR` with `1>&2`.

### Custom Build Scripts

XTE uses Apache Ant to transform your files. If a more complex build is required, such as performing multiple transformations of the same source file, you can write your own build script. All you need to need is ensure that it is called `build.xml` and add it into `./docker/bin`.

## To Fork or not to Fork

To ensure that your custom transformation scenario contains an up-to-date version of the XTE Scenario Template code you should either:

- [create a fork of the xslt scenario template](https://github.com/cambridge-collection/xslt-transformation-engine-scenario-template/fork) in GitHub.com for your custom transformation scenario
- or, add a remote for it in your private repository. This will allow you can pull and merge updates manually.

Creating a fork in GitHub.com is the easiest way to keep up-to-date. All you need to do is log into GitHub and click 'Sync Fork' to ensure they contain the latest versions of the original code. The only issue with this approach is that the repository for your transformation will be publicly visible on GitHub.com. If you want a private repository for your transformation scenario, you'll need to create and manage the connection between your repository and the XTE Template repository manually as per <https://stackoverflow.com/a/30352360>.

Since you should be working on your own custom branch, you will need to manually merge any changes on `main`.

## Test Messages for locally-running AWS dev and AWS Lambda

The `test` directory contains three sample notifications. These notifications can be used to test the functioning of both an AWS dev instance running locally and in an actual AWS lambda. All three will need to be customised with your source bucket name and sample TEI file name as per the instructions below:

1. `tei-source-changed.json` triggers the XSLT transformation process by notifying the lambda that the TEI resource mentioned within it has been changed.
2. `./test/tei-source-removed.json` simulates the removal of the TEI item from the source bucket. It purges all its derivative files from the output bucket.
3. `./test/tei-source-testEvent.json` tests that the lambda is able to respond to unsupported event types.

For these tests to run, you will need:

1. Ensure that the container has been set up properly with the required environment variables. It will also need to be able to access your source and destination buckets. If testing a local aws dev instance, your shell will need [AWS credentials stored in env variables](https://github.com/cambridge-collection/xslt-transformation-engine?tab=readme-ov-file#aws-environment-variables). If you are testing an actual AWS lambda, your lambda will need to have appropriate IAM access to the buckets.
2. The source bucket should contain at least one TEI file.
3. Modify the test events so that they refer to those buckets and your TEI file, replacing:
   - `my-most-awesome-source-b5cf96c0-e114` with your source bucket's name.
   - `my_awesome_tei/sample.xml` with the `full/path/to/yourteifile.xml`.
