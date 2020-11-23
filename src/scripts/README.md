# scripts/

Scripts included in the orb are kept in this directory.

As a part of keeping things separate, it is encouraged to use environment variables to pass through parameters, rather than using the `<< parameter. >>` syntax that CircleCI offers.

## Including Scripts

Utilizing the `circleci orb pack` CLI command, it is possible to import files (such as _shell scripts_), using the `<<include(scripts/script_name.sh)>>` syntax in place of any config key's value.
