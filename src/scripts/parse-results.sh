function parse_exec_results() {
    local KEYS PAIR KEY TMPFILE FIRST_CALL KV_FILE DATE_CMD

    DATE_CMD="date"
    # MacOS built-in date command does not work, try gdate instead
    date --help >dev/null 2>&1 || DATE_CMD="gdate"
    export DATE_CMD
    ${DATE_CMD} >/dev/null 2>&1 || (echo "missing date command."; return 1)

    TMPFILE=$(mktemp)
    jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" <"$1" >"${TMPFILE}"
    KEYS=''

    FIRST_CALL="true"
    if [ $# -gt 1 ]; then
      KEYS="$2"
      KV_FILE="$3"
      FIRST_CALL="false"
    else
      KV_FILE=$(mktemp)
    fi

    while read -r PAIR; do
        KEY=''
        if [ -z "$PAIR" ]; then
            break
        fi
        PAIR_KEY=$(echo "${PAIR}" | cut -d'=' -f1)
        PAIR_VALUE=$(echo "${PAIR}" | cut -d'=' -f2)
        if [ -z "$KEYS" ]; then
            KEY="$PAIR_KEY"
        else
            KEY="$KEYS:$PAIR_KEY"
        fi
        if [[ "${PAIR_VALUE}" == \{* ]] || [[ "${PAIR_VALUE}" == [* ]]; then
            PV_FILE=$(mktemp)
            echo "${PAIR_VALUE}" > "${PV_FILE}"
            parse_exec_results "${PV_FILE}" "${KEY}" "${KV_FILE}"
            rm -f "${PV_FILE}"
        else
            echo "${KEY}" >>"${KV_FILE}"
            echo "${PAIR_VALUE}" >>"${KV_FILE}"
        fi
    done < "${TMPFILE}"
    rm -f "${TMPFILE}"

    if [ "${FIRST_CALL}" = "true" ]; then
      local i j k epoch timestamp suiteTime testcases testName testFailures testTime \
        testLink testSuccess testStatus testStatusCause line kv_key
      declare -A EXEC_RESULTS

      kv_key=""
      while read -r line; do
        if [ "${kv_key}" = "" ]; then
          kv_key="${line}"
        else
          EXEC_RESULTS[$kv_key]="${line}"
          kv_key=""
        fi
      done < "${KV_FILE}"
      rm -f "${KV_FILE}"

      echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
      echo "<testsuites xmlns:xlink=\"http://www.w3.org/1999/xlink\">"
      i=0
      plan="${EXEC_RESULTS[executions:${i}:plan:name]}"
      while [ -n "${plan}" ]; do
        epoch=$(echo "${EXEC_RESULTS[executions:${i}:start_time]}" | sed 's/\([0-9]*\)\([0-9][0-9][0-9]\)/\1.\2/g')
        timestamp=$(${DATE_CMD} -d @"${epoch}" -u +%Y-%m-%dT%H:%M:%S)
        suiteTime=$(((${EXEC_RESULTS[executions:${i}:stop_time]}-${EXEC_RESULTS[executions:${i}:start_time]})/1000))
        declare -a testcases
        j=0
        testFailures=0
        while true; do
          testName=$(get_test_name "${i}" "${EXEC_RESULTS[executions:${i}:journey_executions:${j}:journey_id]}")
          testTime=$(((${EXEC_RESULTS[executions:${i}:journey_executions:${j}:stop_time]}-${EXEC_RESULTS[executions:${i}:journey_executions:${j}:start_time]})/1000))
          testLink=${EXEC_RESULTS[executions:${i}:journey_executions:${j}:app_href]}
          testSuccess=${EXEC_RESULTS[executions:${i}:journey_executions:${j}:success]}
          if [ "${testSuccess}" = "true" ]; then
            testcases[$j]="<testcase classname=\"${plan}\" name=\"${testName}\" time=\"${testTime}\" xlink:type=\"simple\" xlink:href=\"${testLink}\"/>"
          else
            testStatus=${EXEC_RESULTS[executions:${i}:journey_executions:${j}:status]}
            testStatusCause=${EXEC_RESULTS[executions:${i}:journey_executions:${j}:status_cause]}
            if [ -z "${testStatusCause}" ]; then
              testStatusCause=${EXEC_RESULTS[executions:${i}:journey_executions:${j}:failure_summary:error]}
            fi
            testcases[$j]="<testcase classname=\"${plan}\" name=\"${testName}\" time=\"${testTime}\" xlink:type=\"simple\" xlink:href=\"${testLink}\">\
              <failure message=\"${testStatus}\">${testStatusCause}</failure></testcase>"
            testFailures=$((testFailures+1))
          fi
          j=$((j+1))
          if [ -n "${EXEC_RESULTS[executions:${i}:journey_executions:${j}:journey_id]}" ]; then
            testName=$(get_test_name "${i}" "${EXEC_RESULTS[executions:${i}:journey_executions:${j}:journey_id]}")
          else
            break
          fi
        done
        echo "<testsuite name=\"${plan}\" tests=\"${j}\" errors=\"0\" failures=\"${testFailures}\" timestamp=\"${timestamp}\" time=\"${suiteTime}\">"
        k=0
        while [ $k -lt ${#testcases[@]} ]; do
          echo "${testcases[$k]}"
          k=$((k+1))
        done
        echo "</testsuite>"
        i=$((i+1))
        plan=${EXEC_RESULTS[executions:${i}:plan:name]}
      done
      echo "</testsuites>"
    fi
}

function get_test_name() {
  local exec_id journey_id i id test_name
  exec_id="$1"
  journey_id="$2"

  i=0
  id=${EXEC_RESULTS[executions:${exec_id}:journeys:${i}:id]}

  test_name=""
  while [ -n "${id}" ]; do
    if [ "${id}" != "${journey_id}" ]; then
      test_name=${EXEC_RESULTS[executions:${exec_id}:journeys:${i}:name]}
      break
    fi
    i=$((i+1))
    id=${EXEC_RESULTS[executions:${exec_id}:journeys:${i}:id]}
  done

  echo "${test_name}"
}

function parse_results() {
  if [ ! -f "${PARAM_MABL_RESULTS}" ]; then
    echo "No execution result was found."
    return 1
  fi

  if [ -z "${PARAM_MABL_JUNIT}" ]; then
    echo "Missing JUnit report file parameter."
    return 1
  fi

  parse_exec_results "${PARAM_MABL_RESULTS}" > "${PARAM_MABL_JUNIT}"

  return $?
}

# Will not run if sourced for bats.
# View src/tests for more information.
TEST_ENV="bats-core"
if [ "${0#*$TEST_ENV}" == "$0" ]; then
    parse_results
fi
