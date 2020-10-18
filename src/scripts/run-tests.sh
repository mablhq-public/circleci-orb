function run_tests() {
  USER_AGENT="mabl-circleci-orb/MABL_ORB_VERSION"
  
  # Verify parameters
  if [ -z "${PARAM_API_KEY}" ]; then
    echo "api-key mandatory parameter is missing."
    return 1
  fi
  
  if [ -z "${PARAM_ENVIRONMENT_ID}" ] && [ -z "${PARAM_APPLICATION_ID}" ]; then
    echo "Either environment-id or application-id must be provided."
    return 1
  fi
  
  if [ -n "${PARAM_ENVIRONMENT_ID}" ] && [[ ! "${PARAM_ENVIRONMENT_ID}" == *-e ]]; then
    echo "environment-id parameter must end with a '-e'."
    return 1
  fi
  
  if [ -n "${PARAM_APPLICATION_ID}" ] && [[ ! "${PARAM_APPLICATION_ID}" == *-a ]]; then
    echo "application-id parameter must end with a '-a'."
    return 1
  fi
  
  BROWSER_TYPES=""
  if [ -n "${PARAM_BROWSERS}" ]; then
    for BROWSER in $(echo "${PARAM_BROWSERS}" | sed 's/,/ /g'); do
      case ${BROWSER} in
        chrome|firefox|internet_explorer|safari)
          ;;
        *)
          echo "Invalid browser value provided: ${PARAM_BROWSERS}"
          echo "Permitted values: chrome, firefox, internet_explorer, safari"
          exit 1
          ;;
      esac
    done
    BROWSER_TYPES=$(echo "${PARAM_BROWSERS}" | sed 's/^/\"/' | sed 's/$/\"/' | sed 's/,/\",\"/g')
  fi
  
  shopt -s extglob
  if [ -n "${PARAM_URL}" ] && [[ "${PARAM_URL}" != "http*(s)://*" ]]; then
    echo "Invalid URL parameter provided: ${PARAM_URL}"
    return 1
  fi
  
  # Create JSON payload for deployment event
  declare -A PARAMS
  declare -A PLAN_OVERRIDES
  
  if [ -n "${PARAM_ENVIRONMENT_ID}" ]; then
    PARAMS[environment_id]="${PARAM_ENVIRONMENT_ID}"
  fi
  
  if [ -n "${PARAM_APPLICATION_ID}" ]; then
    PARAMS[application_id]="${PARAM_APPLICATION_ID}"
  fi
  
  if [ -n "${PARAM_LABELS}" ]; then
    LABELS=$(echo "${PARAM_LABELS}" | sed 's/^/\"/' | sed 's/$/\"/' | sed 's/,/\",\"/g')
    PARAMS[plan_labels]="[${LABELS}]"
  fi
  
  if [ -n "${PARAM_MABL_BRANCH}" ]; then
    PARAMS[source_control_tag]="${PARAM_MABL_BRANCH}"
  fi
  
  if [ -n "${BROWSER_TYPES}" ]; then
    PLAN_OVERRIDES[browser_types]="[${BROWSER_TYPES}]"
  fi
  
  if [ -n "${PARAM_URL}" ]; then
    PLAN_OVERRIDES[uri]="${PARAM_URL}"
  fi
  
  if [ -n "${PARAM_REVISION}" ]; then
    PLAN_OVERRIDES[revision]="${PARAM_REVISION}"
  fi
  
  PLAN_OVERRIDES_JSON=""
  if [ ${#PLAN_OVERRIDES[@]} -gt 0 ]; then
    PLAN_OVERRIDES_JSON="\"plan_overrides\": { "
    for key in "${!PLAN_OVERRIDES[@]}"; do
      VALUE=${PLAN_OVERRIDES[$key]}
      if [[ "${VALUE}" != \[* ]]; then
        VALUE="\"${VALUE}\""
      fi
      PLAN_OVERRIDES_JSON="${PLAN_OVERRIDES_JSON} \"${key}\":${VALUE},"
    done
    PLAN_OVERRIDES_JSON=$(echo "${PLAN_OVERRIDES_JSON}" | sed 's/,$/ },/g')
  fi
  
  PARAMS_JSON="{ "
  for key in "${!PARAMS[@]}"; do
    VALUE=${PARAMS[$key]}
    if [[ "${VALUE}" != \[* ]]; then
        VALUE="\"${VALUE}\""
    fi
    PARAMS_JSON="${PARAMS_JSON} \"${key}\":${VALUE},"
  done
  
  if [ -n "${PLAN_OVERRIDES_JSON}" ]; then
    PARAMS_JSON="${PARAMS_JSON} ${PLAN_OVERRIDES_JSON}"
  fi
  
  ACTIONS_JSON="\"actions\": { \"rebaseline_images\":\"${PARAM_REBASELINE_IMAGES}\","
  ACTIONS_JSON="${ACTIONS_JSON}\"set_static_baseline\":\"${PARAM_SET_STATIC_BASELINE}\" }"
  
  PARAMS_JSON="${PARAMS_JSON}${ACTIONS_JSON} }"
  debug "Parameters: ${PARAMS_JSON}"
  
  # Create output directory
  mkdir -p test-results/mabl
  
  # Submit deployment event
  deployment_event=$(curl -s "https://api.mabl.com/events/deployment" -u "key:${PARAM_API_KEY}" -A "${USER_AGENT}" -H 'Content-Type:application/json' -d "${PARAMS_JSON}")
  debug "Received event: $deployment_event"
  event_id=$(echo "${deployment_event}" | jq -r '.id')
  if [ -n "${event_id}" ] && [[ "${event_id}" != *-v ]]; then
    echo "Failed to submit deployment event."
    return 1
  fi
  workspace_id=$(echo "${deployment_event}" | jq -r '.workspace_id')
  echo "Successfully triggered deployment at https://app.mabl.com/workspaces/${workspace_id}/events/${event_id}"
  echo "${deployment_event}" > test-results/mabl/deployment_event.json
  
  # Poll execution result if configured to do so
  succeeded=false
  failed_plans=0
  if [ "${PARAM_AWAIT_COMPLETION}" = "true" ]; then
    complete=false
    while [ ${complete} == false ]; do
      echo "Waiting for executions to complete..."
      sleep 10
      results=$(curl -s "https://api.mabl.com/execution/result/event/${event_id}" -A "${USER_AGENT}" -u "key:${PARAM_API_KEY}")
      debug "execution event result: $results"
      plan_metrics=$(echo "${results}" | jq '.plan_execution_metrics')
      if [ "${plan_metrics}" == "null" ]; then
        continue
      fi
      failed_plans=$(echo "${plan_metrics}" | jq -r '.failed')
      event_status=$(echo "${results}" | jq -r .event_status.succeeded)
      case ${event_status} in
      null)
        continue
        ;;
      true)
        succeeded=true
        complete=true
        ;;
      false)
        succeeded=false
        complete=true
        ;;
      *)
        debug "Unexpected event status received: ${event_status}"
        succeeded=false
        complete=false
        ;;
      esac
  
    done
    echo
    echo "${results}" >test-results/mabl/execution_result.json
    if [ "${PARAM_DEBUG}" = "true" ]; then
      echo "Full Results:"
      cat test-results/mabl/execution_result.json
      echo
    fi
    if [ ${succeeded} == true ]; then
      echo "All plans passed."
      return 0
    else
      echo "Some plans have failed. Total number of failed plans: ${failed_plans}"
      return 1
    fi
  fi
}

debug() {
  if [ "${PARAM_DEBUG}" = "true" ]; then
    echo "$1"
  fi
}
