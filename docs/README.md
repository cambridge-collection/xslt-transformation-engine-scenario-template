# XSLT Transformation Engine (XTE) Scenario Template

This repository provides a base template for rolling your own implementation of the [Cambridge Digital Collection XSLT Transformation Engine (XTE)](https://github.com/cambridge-collection/xslt-transformation-engine). It can be deployed either as:

* an AWS Lambda function that listens for SQS notifications about changes in your source S3 bucket, transforms the referenced file with your XSLT, and writes the result to the bucket specified by the `AWS_OUTPUT_BUCKET` environment variable.
* a standalone build that processes one or more items from `./source` and writes the outputs to `./out`. It can be run locally on your computer, in a GitHub Action or CI/CD system.

## Prerequisites

- Docker [<https://docs.docker.com/get-docker/>]

## Rolling your own transformation scenario

### Basic Instructions

1. Start from this template:
   - For a new repository, click `Use this template` in GitHub and fill in the dialog to create your new repository. Then, use git clone to create a local copy on your hard drive.
   - For an existing repository, follow the import workflow described in [Staying in Sync with the Template Repository](#staying-in-sync-with-the-template-repository).
2. Create a working branch in your repository for your customisations. If you use a branch other than `main`, set it as the default under Settings -> General.
3. Copy your XSLT into `./docker/xslt`.
4. Define the `XSLT_ENTRYPOINT` environment variable so that it points to your custom xslt. This variable takes `./docker` as its root. If your custom XSLT were is `xslt/my-custom.xsl`, `XSLT_ENTRYPOINT` would be set to `xslt/my-custom.xsl`.
5. Set any other required and optional environment variables that might need changing. See <https://github.com/cambridge-collection/xslt-transformation-engine?tab=readme-ov-file#required-environment-variables-for-both-aws-and-standalone-versions> for a list of all the available variables.
6. Test your container locally by using the docker compose file for your specific environment (_i.e._ `compose-aws.yml` for AWS or `compose-standalone.yml` for standalone) as per the instructions on <https://github.com/cambridge-collection/xslt-transformation-engine>.

### Required Environment Variables (common to AWS and standalone)

Both deployment styles share a core set of environment variables; additional ones are noted in the AWS- and standalone-specific sections below.

| Variable Name | Description | Default |
| --- | --- | --- |
| `ENVIRONMENT` | Environment type. Set to `standalone` for local compose runs, or `aws` when the Lambda entrypoint should run. |  |
| `INSTANCE_NAME` | Root name for container instances. Compose files append `-standalone`/`-aws`. | `xslt-transformation-engine` |
| `ANT_BUILDFILE` | Ant buildfile path relative to the container working directory. | `bin/build.xml` |
| `ANT_TARGET` | Ant target executed by the buildfile. | `full` |
| `XSLT_ENTRYPOINT` | Entry XSLT stylesheet path relative to the image `xslt/` directory. | `xslt/TEI-to-HTML.xsl` |
| `OUTPUT_EXTENSION` | Extension applied to transformed outputs (for example `html` or `xml`). | `html` |
| `EXPAND_DEFAULT_ATTRIBUTES` | When `true`, expands schema default attributes during transformation. | `false` |
| `ANT_LOG_LEVEL` | Ant verbosity (`warn`, `default`, `verbose`, or `debug`; case-insensitive). | `default` |
| `WELLFORMEDNESS_FILTER` | When `true`, only well-formed XML files proceed to transformation. It is recommended that it be set to false in the AWS compose profile. | `false` |

For deeper coverage of every supported variable (including AWS- and standalone-specific options), see [XTE environment reference](https://github.com/cambridge-collection/xslt-transformation-engine?tab=readme-ov-file#required-environment-variables-for-both-aws-and-standalone-versions).

Docker builds local test images for your host architecture (unless overridden with `DOCKER_DEFAULT_PLATFORM`). For AWS Lambda deployment, build for `linux/amd64`. See [Building the Lambda for deployment in AWS](#building-the-lambda-for-deployment-in-aws).

### Advanced Transformation Scenarios

The above approach will work for transformation scenarios that involve transforming one (or more) source XML files into output files using XSLT. This is the most common pattern for transforming XML documents. Sometimes, however, more complicated transforms are necessary. For example, your transformation might depend on the presence of certain supplementary source files (_e.g._ various authority files) or you might need to change the directory structure of your output files (_e.g._ flattening the directory hierarchy of the outputs); or you might need to generate multiple outputs, say html for viewing; json for indexing. You can extend your transformation scenario by customising the Ant build at any point in the lifecycle with its extension points.

### Extending the Build

It is easy to override the build. If your build is complex, it may be easier to just put it into `docker/bin/build.xml` (the default buildfile) and ensure that the task you want to run is named `full` (the default task).

Alternatively, you can extend the build by patching onto one of the many hooks available in the core XTE build. This can result in a far smaller buildfile and allows you to take advantage of a lot of the pre-existing pipelines within the XTE build.

To do this:

1. copy `examples/build/sample-importing.xml` in `docker/bin`. If you name it `build.xml`, it will automatically work. If you want to name it anything else, you will have to set `ANT_BUILDFILE`.
2. Alter the relevant hooks within the build file. You can either leave the remaining hooks in the file or you can delete them. Do NOT delete the `<import file="./xte/core.xml"/>` towards the end of the file.

#### Key Files

- `docker/bin/build.xml`: main entry point for the scenario build. It imports the core XTE build logic `./xte/core.xml`. This gives you a ready-made transformation pipeline. It also gives you the following macros:
  - `fs:select-files`: builds a fileset from an includes file or glob.
  - `fs:requested-files`: resolves the requested inputs (newline-delimited) from `includes_file` or `files-to-process`.
  - `fs:xslt-transform`: runs Saxon with optional default-attribute expansion.

#### Pipeline Overview

The default pipeline proceeds as follows:

1. `cleanup`: clears previous outputs and prepares directories.
2. `wellformedness`: optionally filters out non-well-formed XML if `WELLFORMEDNESS_FILTER=true`.
3. `before-transform` (optional hook).
4. `transform`: performs the XSLT using `XSLT_ENTRYPOINT` and writes to `transform.out`.
5. `after-transform` (optional hook).
6. `before-release` (optional hook).
7. `release-outputs`: copies results to local disk (`standalone`) or S3 (`aws`).

#### Extension Points and Hooks

Each hook target receives a source directory and an output directory. Override or extend these targets in your Ant build to add behaviour.

Properties such as `source.dir` (must remain `../source`) and `release.out.dir` (must remain `../out`) should not be changed. Override other properties via your importing build file as required.

- **before-transform** (runs before Saxon)
  - Source: `wellformedness.out.dir`
  - Output: `transform.before.out.dir`
- **after-transform**
  - Source: `transform.out`
  - Output: `transform.after.out.dir`
- **before-release**
  - Source: `transform.after.out.dir`
  - Output: `release.before.out.dir`

#### Using the Sample Build

The sample Ant build at `examples/build/build.xml` demonstrates how to import the core build and override extension points. Copy it into `./docker/bin` (for example as `sample-importing.xml`) when you want to experiment without altering `bin/build.xml`:

```bash
cp examples/build/build.xml docker/bin/sample-importing.xml
export ANT_BUILDFILE=bin/sample-importing.xml \
docker compose --env-file ./examples/env/sample.env -f compose-standalone.yml up --force-recreate --build
```

Before starting the standalone compose stack, make sure the host has the expected mount points:

- populate `./source/` with the XML you want to process. If your inputs live elsewhere in your repo, remove the default `source/` directory and replace it with a symlink pointing at the real location (for example `rm -rf source && ln -s ../data/datasets/tei source`).
- create `./out/` if it does not already exist (`mkdir -p out`). Compose refuses to start when the target directory is missing, and the container writes transformed files there.

### Custom Build Scripts

For more complex scenarios you can supply your own Ant build file. Place it under `./docker/bin` (for example `docker/bin/my-build.xml`) and set `ANT_BUILDFILE` to point to it. Import `docker/bin/xte/core.xml` within your custom file to reuse the shared pipeline and override the targets you need.

You can start from the sample at `examples/build/build.xml`: copy it into `./docker/bin` and adapt the hooks/targets to your scenario before pointing `ANT_BUILDFILE` at it.

### Example GitHub Action: Semantic Release for Scenario Repos

Use the sample workflow at `examples/gh_actions/semantic-versioning.yml` when you want automated semantic versioning in a scenario repository:

- Copy the file into `.github/workflows/semantic-versioning.yml` (or a name of your choosing).
- It checks out the repository and runs `semantic-release` to tag the current commit (`v${version}`) and publish release notes back to GitHub using `${{ secrets.GITHUB_TOKEN }}`.
- Releases are driven by [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/); follow that format so the correct semver bump is picked.
- Start by copying `.releaserc.json` into your repository and adapt the rules (branches, releaseRules, sections) to match your needs before enabling the workflow.
- Update the `on.push.branches` list if you ship from a branch other than `main`.

### Example GitHub Action: Maintain Output Snapshots and Sync to S3

The workflow at `examples/gh_actions/build-and-release.yml` rebuilds XML outputs when the `release` branch changes (or on manual dispatch) and keeps an S3 bucket in sync.

- Checks out the repository with full history so it can diff against the prior success tag.
- Calculates the transform scope (`changed` vs `all`) and records affected files in `source/changed-files.txt` and `source/deleted-files.txt`.
- Assumes an AWS IAM role, removes stale objects for deleted XML sources, then runs the standalone Docker transform with `docker compose`.
- Uploads the refreshed `./out/` directory to S3 and moves the success tag (`LAST_SUCCESS_TAG_NAME`) to the current commit.
- Always tears down the Docker Compose stack at the end.

You need to setup AWS and GitHub configuration for least-privilege uploads

1. **Configure GitHub OIDC in AWS (if not already set up).** Create an identity provider with URL `https://token.actions.githubusercontent.com` and audience `sts.amazonaws.com`.
2. **Create a restricted S3 policy.** Replace the placeholders before saving:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": "s3:ListBucket",
         "Resource": "arn:aws:s3:::BUCKET_NAME",
         "Condition": {
           "StringLike": {
             "s3:prefix": ["bucket/prefix/*", "bucket/prefix"]
           }
         }
       },
       {
         "Effect": "Allow",
         "Action": ["s3:PutObject", "s3:DeleteObject"],
         "Resource": "arn:aws:s3:::BUCKET_NAME/bucket/prefix/*"
       }
     ]
   }
   ```
3. **Create an IAM role for GitHub Actions** and attach the policy. Use a trust policy similar to:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:owner/repo:ref:refs/heads/main"
           }
         }
       }
     ]
   }
   ```
   Adjust `owner/repo` (and the branch if required) to match your project, then note the role ARN.
4. **Add GitHub secrets** (`Settings → Secrets and variables → Actions`) for each of the following:.

	| Variable | Scope | Source | Description |
| --- | --- | --- | --- |
| `AWS_S3_UPLOAD_ROLE_ARN` | [req] | secret | IAM role ARN assumed via GitHub OIDC to gain S3 write access. |
| `XTE_OUTPUT_BUCKET` | [req] | secret | Destination S3 bucket that receives the transformed outputs. |
| `AWS_REGION` | [req] | secret or repository variable | AWS region used by `aws-actions/configure-aws-credentials` and subsequent `aws s3` commands. |
| `XTE_OUTPUT_PREFIX` | [opt] | secret or repository variable | Optional object prefix (folder) within the destination bucket. Leave blank for the bucket root. |

5. Set the additional repository variables (`XSLT_ENTRYPOINT`, `TEI_FILE`, `ANT_LOG_LEVEL`, `DEFAULT_RUN_SCOPE`, `LAST_SUCCESS_TAG_NAME`, etc.) that control transform behaviour as documented at [XTE environment reference](https://github.com/cambridge-collection/xslt-transformation-engine?tab=readme-ov-file#required-environment-variables-for-both-aws-and-standalone-versions).

**Note**: *`DEFAULT_RUN_SCOPE`’s `all` currently does not deal with deleted resources.* 

## Keeping the XTE scaffolding up-to-date

1. **Add XTE Template origin:**
   ```bash
   git remote add xte-template-origin git@github.com:cambridge-collection/xslt-transformation-engine-scenario-template.git
   ```

2. **Import or review template changes on a separate branch:**
   ```bash
   git checkout -b xte-template-sync xte-template-origin/main
   ```

3. **Create a temporary merge branch off your template branch:**
   ```bash
   git checkout xte-template-sync
   git checkout -b xte_merge_tmp
   ```

4. **Bring your main branch onto the temporary branch and resolve conflicts there:**
   ```bash
   git merge main
   ```
   Resolve any conflicts on `xte_merge_tmp`and make any adjustments that XTE requires. Follow the [Basic Instructions](#basic-instructions) to ensure files and configuration land in the right places before you merge. Test it thoroughly in standalone mode (and AWS mode, if deploying that way).
   This process will be harder the first time you attempt to base your repository on the XTE Template. Once it has been based on the template, updates should be a lot easier to manage.

5. **Fast-forward main to include the merged changes:**
   ```bash
   git checkout main
   git merge xte_merge_tmp
   ```
   
6. **Once the merge is complete, remove the scratch branches to keep history tidy:**
   ```bash
   git branch -d xte_merge_tmp
   git branch -d xte-template-sync
   ```

## Test Messages for locally-running AWS and AWS Lambda

The `test` directory contains three sample notifications. These notifications can be used to test the functioning of both an AWS instance running locally and in an actual AWS lambda. All three will need to be customised with your source bucket name and sample TEI file name as per the instructions below:

1. `tei-source-changed.json` triggers the XSLT transformation process by notifying the lambda that the TEI resource mentioned within it has been changed.
2. `./test/tei-source-removed.json` simulates the removal of the TEI item from the source bucket. It purges all its derivative files from the output bucket.
3. `./test/tei-source-testEvent.json` tests that the lambda is able to respond to unsupported event types.

For these tests to run, you will need:

1. Ensure that the container has been set up properly with the required environment variables. It will also need to be able to access your source and destination buckets. If testing a local AWS instance, your shell will need [AWS credentials stored in env variables](https://github.com/cambridge-collection/xslt-transformation-engine?tab=readme-ov-file#aws-environment-variables). If you are testing an actual AWS lambda, your lambda will need to have appropriate IAM access to the buckets.
2. The source bucket should contain at least one TEI file.
3. Modify the test events so that they refer to those buckets and your TEI file, replacing:
   - `my-most-awesome-source-b5cf96c0-e114` with your source bucket's name.
   - `my_awesome_tei/sample.xml` with the `full/path/to/yourteifile.xml`.
