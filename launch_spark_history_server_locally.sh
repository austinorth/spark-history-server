#!/usr/bin/env bash
#
# Helps start/stop a local Spark History Server for viewing Spark event logs from S3.

set -e

readonly CLASS="org.apache.spark.deploy.history.HistoryServer"

#######################################
# Displays help information about script usage
# Globals:
#   None
# Arguments:
#   None
#######################################
function print_help() {
  cat <<EOF
A helper script to start/stop your local Spark History Server

Syntax: $(basename "$0") {start|stop|restart|status|help} {options}

Actions:
  start   Start your local Spark History Server at 'localhost:18080'
  stop    Stop the running Spark History Server
  restart Restart the Spark History Server
  status  Print the current running container details
  help    Print this message

Start/restart options:
  -sb, --S3_BUCKET             S3 bucket name where you have your Spark EventLogs (REQUIRED)
  -sp, --S3_BUCKET_PREFIX      S3 bucket prefix where Spark EventLogs are stored (REQUIRED)
  -r,  --AWS_REGION            AWS Region where the S3 bucket is located (Default: us-east-1)
  -cn, --CONTAINER_NAME        Custom Container Name (Default: spark-history-server)
  -du, --DOCKER_USER           Local user for docker image (Default: current user)
  -ak, --AWS_ACCESS_KEY_ID     AWS access key ID
  -as, --AWS_SECRET_ACCESS_KEY AWS secret access key
  -at, --AWS_SESSION_TOKEN     AWS session token

Examples:
  $(basename "$0") start -sb my-bucket -sp spark/history/events
  $(basename "$0") stop
  $(basename "$0") restart -sb my-bucket -sp spark/history/events
  $(basename "$0") status
  $(basename "$0") help
EOF
}

#######################################
# Starts the Spark History Server
# Globals:
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY
#   AWS_SESSION_TOKEN
#   ENDPOINT
#   CONTAINER_NAME
#   CLASS
# Arguments:
#   S3 bucket name
#   S3 bucket prefix
#   Docker user
#######################################
function start() {
  local s3_bucket="$1"
  local s3_prefix="$2"
  local docker_user="$3"
  local log_dir="s3a://${s3_bucket}/${s3_prefix}"
  local docker_image="${docker_user}/spark-web-ui:latest"

  docker run -itd --name "${CONTAINER_NAME}" \
    -e SPARK_DAEMON_MEMORY="2g" \
    -e SPARK_DAEMON_JAVA_OPTS="-XX:+UseG1GC" \
    -e SPARK_HISTORY_OPTS="${SPARK_HISTORY_OPTS} \
      -Dspark.history.fs.logDirectory=${log_dir} \
      -Dspark.hadoop.fs.s3a.access.key=${AWS_ACCESS_KEY_ID} \
      -Dspark.hadoop.fs.s3a.secret.key=${AWS_SECRET_ACCESS_KEY} \
      -Dspark.hadoop.fs.s3a.session.token=${AWS_SESSION_TOKEN} \
      -Dspark.hadoop.fs.s3a.endpoint=${ENDPOINT} \
      -Dspark.hadoop.fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.TemporaryAWSCredentialsProvider" \
    -p 18080:18080 "${docker_image}" "/opt/spark/bin/spark-class ${CLASS}"

  sleep 10
  echo "Spark History Server running @ http://localhost:18080 "
  echo
}

#######################################
# Stops the Spark History Server
# Globals:
#   CONTAINER_NAME
# Arguments:
#   None
#######################################
function stop() {
  set +e
  docker stop "${CONTAINER_NAME}"
  docker rm "${CONTAINER_NAME}"
  set -e
  sleep 10
}

#######################################
# Shows the status of the Spark History Server
# Globals:
#   CONTAINER_NAME
# Arguments:
#   None
#######################################
function status() {
  docker ps --filter "name=${CONTAINER_NAME}"
}

# Parse command line arguments
ACTION=""
S3_BUCKET=""
S3_BUCKET_PREFIX=""
AWS_REGION="us-east-1"
CONTAINER_NAME="spark-history-server"
DOCKER_USER="${USER}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    start|stop|restart|status|help)
      ACTION="$1"
      ;;
    -sb|--S3_BUCKET)
      S3_BUCKET="$2"
      shift
      ;;
    -sp|--S3_PREFIX)
      S3_BUCKET_PREFIX="$2"
      shift
      ;;
    -r|--AWS_REGION)
      AWS_REGION="$2"
      shift
      ;;
    -cn|--CONTAINER_NAME)
      CONTAINER_NAME="$2"
      shift
      ;;
    -du|--DOCKER_USER)
      DOCKER_USER="$2"
      shift
      ;;
    -ak|--AWS_ACCESS_KEY_ID)
      export AWS_ACCESS_KEY_ID="$2"
      shift
      ;;
    -as|--AWS_SECRET_ACCESS_KEY)
      export AWS_SECRET_ACCESS_KEY="$2"
      shift
      ;;
    -at|--AWS_SESSION_TOKEN)
      export AWS_SESSION_TOKEN="$2"
      shift
      ;;
    *)
      echo "Error: Invalid argument."
      print_help
      exit 1
  esac
  shift
done

readonly ENDPOINT="s3.${AWS_REGION}.amazonaws.com"

# Execute requested action
case "${ACTION}" in
  status)
    echo "Print status: "
    status
    ;;
  start)
    if [[ -z "${S3_BUCKET}" || -z "${S3_BUCKET_PREFIX}" ]]; then
      echo "Error: S3 bucket and prefix are required for start action."
      print_help
      exit 1
    fi

    echo "Starting Spark History Server: "
    start "${S3_BUCKET}" "${S3_BUCKET_PREFIX}" "${DOCKER_USER}"
    status
    ;;
  stop)
    echo "Stopping Spark History Server: "
    stop
    ;;
  restart)
    if [[ -z "${S3_BUCKET}" || -z "${S3_BUCKET_PREFIX}" ]]; then
      echo "Error: S3 bucket and prefix are required for restart action."
      print_help
      exit 1
    fi

    echo "Restarting Spark History Server: "
    stop
    start "${S3_BUCKET}" "${S3_BUCKET_PREFIX}" "${DOCKER_USER}"
    status
    ;;
  *)
    print_help
    exit 1
esac

exit 0
