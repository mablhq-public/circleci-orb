setup() {
    source ./src/scripts/parse-results.sh
    if [ ! -d target ]; then
        mkdir target
    fi
}

@test '1: Missing results file' {
    unset PARAM_MABL_RESULTS
    unset PARAM_MABL_JUNIT

    run parse_results
    [ "$status" -eq 1 ]
    [ "$output" = "No execution result was found." ]
}

@test '2: Invalid results filename' {
    export PARAM_MABL_RESULTS="some-invalid-file-name"
    unset PARAM_MABL_JUNIT

    run parse_results
    [ "$status" -eq 1 ]
    [ "$output" = "No execution result was found." ]
}

@test '3: Missing output file' {
    export PARAM_MABL_RESULTS=$(mktemp)
    unset PARAM_MABL_JUNIT

    run parse_results
    [ "$status" -eq 1 ]
    [ "$output" = "Missing JUnit report file parameter." ]

    rm -f "${PARAM_MABL_RESULTS}"
}

@test '4: Parse output' {
    export PARAM_MABL_RESULTS="src/tests/execution_result.json"
    export PARAM_MABL_JUNIT="target/report.xml"
    export EXPECTED_RESULT="src/tests/expected-report.xml"

    run parse_results
    [ "$status" -eq 0 ]
    diff -q "${PARAM_MABL_JUNIT}" "${EXPECTED_RESULT}" || [ 0 -eq 1 ]
}
