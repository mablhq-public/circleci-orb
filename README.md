# mabl trigger-tests Orb

[![CircleCI Build Status](https://circleci.com/gh/mablhq/circleci-orb.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/mablhq/circleci-orb) [![CircleCI Orb Version](https://img.shields.io/badge/endpoint.svg?url=https://badges.circleci.io/orb/mabl/trigger-tests)](https://circleci.com/orbs/registry/orb/mabl/trigger-tests) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/mablhq/circleci-orb/master/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)

Integrate your mabl tests directly into your CircleCI pipeline. You can use the trigger-tests Orb to automatically trigger specific environment or application plans to run as a deployment task. The report of the tests are available in the JUnit XML format. This means that in addition to viewing the test results in the mabl webapp, you can inspect them directly in the CircleCI interface and you can also import the test results into external test reporting tools.

## Resources

[CircleCI Orb Registry Page](https://circleci.com/developer/orbs/orb/mabl/trigger-tests) - The official registry page of this orb for all versions, executors, commands, and jobs described.

[CircleCI Orb Docs](https://circleci.com/docs/2.0/orb-intro/#section=configuration) - Docs for using and creating CircleCI Orbs.

### How to Contribute

We welcome [issues](https://github.com/mablhq/circleci-orb/issues) to and [pull requests](https://github.com/mablhq/circleci-orb/pulls) against this repository!

### How to Publish

* Create and push a branch with your new features.
* When ready to publish a new production version, create a Pull Request from fore _feature branch_ to `main`.
* The title of the pull request must contain a custom semver tag: `[semver:<segment>]` where `<segment>` is replaced by one of the following values.

| Increment | Description|
| ----------| -----------|
| major     | Issue a 1.0.0 incremented release|
| minor     | Issue a x.1.0 incremented release|
| patch     | Issue a x.x.1 incremented release|
| skip      | Do not issue a release|

Example: `[semver:major]`

* Squash and merge. Ensure the semver tag is preserved and entered as a part of the commit message.
* On merge, after manual approval, the orb will automatically be published to the Orb Registry.

For further questions/comments about this or other orbs, visit the Orb Category of [CircleCI Discuss](https://discuss.circleci.com/c/orbs).

### Notes for Development on macOS

#### Prerequisites

The bash shipped with macOS is old. To run the integration locally, install bash from brew using
`brew install bash` and invoke `/usr/local/bin/bash`.

Install `bats` - the Bash unit test framework - using `brew install bats`.

Install `circleci` command-line using `brew install circleci`.

### Running Tests Locally

Set environment variables. The application ID and environment ID can be anything.
Note that PARAM_API_KEY is supposed to have an environment variable name assigned.

```bash
export PARAM_API_KEY=MABL_API_KEY
export PARAM_APPLICATION_ID=mZdHH6jnBGLW6G56mMK3tg-a
export PARAM_ENVIRONMENT_ID=WRZ3WcvFQ2MTgqC41ZxmMw-e
export MABL_API_KEY=<a fake or real API key>
```

If you want to kick off test runs, then set the `MABL_API_KEY` variable to a real
key and also set the following environment variables.

```bash
export MABL_APPLICATION_ID=mZdHH6jnBGLW6G56mMK3tg-a
export MABL_ENVIRONMENT_ID=WRZ3WcvFQ2MTgqC41ZxmMw-e
```

To run the tests, execute

```bash
bats src/tests/run-tests.bats
```
