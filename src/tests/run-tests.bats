setup() {
    source ./src/scripts/run-tests.sh
}

@test '1: Require API key' {
    unset PARAM_API_KEY
    run run_tests
    [ "$status" -eq 1 ]
    [ "$output" = "api-key mandatory parameter is missing." ]
}

@test '2: Missing API key value' {
    export PARAM_API_KEY="TEST_API_KEY"
    unset TEST_API_KEY
    run run_tests
    [ "$status" -eq 1 ]
    [ "$output" = "missing API key value." ]
}


@test '3: Either environment or application ID must be present' {
    export PARAM_API_KEY="TEST_API_KEY"
    export TEST_API_KEY="example-key"
    unset PARAM_APPLICATION_ID
    unset PARAM_ENVIRONMENT_ID
    run run_tests
    [ "$status" -eq 1 ]
    [ "$output" = "Either environment-id or application-id must be provided." ]
}

@test '4: Invalid application ID' {
    export PARAM_API_KEY="TEST_API_KEY"
    export TEST_API_KEY="example-key"
    export PARAM_APPLICATION_ID="invalid-id"
    run run_tests
    [ "$status" -eq 1 ]
    [ "$output" = "application-id parameter (${PARAM_APPLICATION_ID}) must end with a '-a'." ]
}

@test '5: Invalid environment ID' {
    export PARAM_API_KEY="TEST_API_KEY"
    export TEST_API_KEY="example-key"
    export PARAM_ENVIRONMENT_ID="invalid-id"
    run run_tests
    [ "$status" -eq 1 ]
    [ "$output" = "environment-id parameter (${PARAM_ENVIRONMENT_ID}) must end with a '-e'." ]
}

@test '6: Invalid browser type - single value' {
    export PARAM_API_KEY="TEST_API_KEY"
    export TEST_API_KEY="example-key"
    export PARAM_APPLICATION_ID="example-application-a"
    export PARAM_ENVIRONMENT_ID="example-environment-e"
    export PARAM_BROWSERS="mosaic"

    run run_tests
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Invalid browser value provided: ${PARAM_BROWSERS}" ]
}

@test '7: Invalid browser type - multiple values' {
    export PARAM_API_KEY="TEST_API_KEY"
    export TEST_API_KEY="example-key"
    export PARAM_APPLICATION_ID="example-application-a"
    export PARAM_ENVIRONMENT_ID="example-environment-e"
    export PARAM_BROWSERS="firefox,netscape navigator"

    run run_tests
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Invalid browser value provided: ${PARAM_BROWSERS}" ]
}

@test '8: Invalid URL - gopher' {
    export PARAM_API_KEY="TEST_API_KEY"
    export TEST_API_KEY="example-key"
    export PARAM_APPLICATION_ID="example-application-a"
    export PARAM_ENVIRONMENT_ID="example-environment-e"
    export PARAM_URL="gopher://vein.hu/"

    run run_tests
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Invalid URL parameter provided: ${PARAM_URL}" ]
}

@test '9: Invalid URL - missing scheme' {
    export PARAM_API_KEY="TEST_API_KEY"
    export TEST_API_KEY="example-key"
    export PARAM_APPLICATION_ID="example-application-a"
    export PARAM_ENVIRONMENT_ID="example-environment-e"
    export PARAM_URL="ietf.org"

    run run_tests
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Invalid URL parameter provided: ${PARAM_URL}" ]
}

@test '10: Invalid key - deployment failure' {
    export PARAM_API_KEY="TEST_API_KEY"
    export TEST_API_KEY="example-key"
    export PARAM_APPLICATION_ID="example-application-a"
    export PARAM_ENVIRONMENT_ID="example-environment-e"

    run run_tests
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Failed to submit deployment event." ]
}

@test '11: Kick off deployment and do not wait for results' {
    if [ -z "${MABL_API_KEY}"] || [ -z "${MABL_APPLICATION_ID}"] || [ -z "${MABL_ENVIRONMENT_ID}" ]; then
        skip "Skipping test as all of MABL_API_KEY, MABL_APPLICATION_ID, MABL_ENVIRONMENT_ID must be set"
    fi
    export PARAM_API_KEY="MABL_API_KEY"
    export PARAM_APPLICATION_ID="${MABL_APPLICATION_ID}"
    export PARAM_ENVIRONMENT_ID="${MABL_ENVIRONMENT_ID}"
    export PARAM_AWAIT_COMPLETION="false"
    run run_tests
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" = Successfully\ triggered\ deployment\ at\ * ]]
}

@test '12: Kick off deployment and wait for results' {
    if [ -z "${MABL_API_KEY}"] || [ -z "${MABL_APPLICATION_ID}"] || [ -z "${MABL_ENVIRONMENT_ID}" ]; then
        skip "Skipping test as all of MABL_API_KEY, MABL_APPLICATION_ID, MABL_ENVIRONMENT_ID must be set"
    fi
    export PARAM_API_KEY="MABL_API_KEY"
    export PARAM_APPLICATION_ID="${MABL_APPLICATION_ID}"
    export PARAM_ENVIRONMENT_ID="${MABL_ENVIRONMENT_ID}"
    export PARAM_AWAIT_COMPLETION="true"
    run run_tests
    [ "$status" -eq 0 ]
    [ "${lines[-1]}" = "All plans passed." ]
}

@test '13: Invalid URL - environment variable' {
    export PARAM_API_KEY="TEST_API_KEY"
    export TEST_API_KEY="example-key"
    export PARAM_APPLICATION_ID="example-application-a"
    export PARAM_ENVIRONMENT_ID="example-environment-e"
    export PARAM_URL="\$URL_ENV_VARIABLE"
    export URL_ENV_VARIABLE="ftp://ftp.funet.fi"

    run run_tests
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Invalid URL parameter provided: ${URL_ENV_VARIABLE}" ]
}
