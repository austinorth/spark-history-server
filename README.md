# Spark History Server

A Helm chart and Docker container for deploying Spark History Server (Spark Web
UI) to monitor the metrics and performance of your Spark jobs.

## Overview

This project provides two main components:

1. A Docker image for Spark History Server configured to read Spark Event Logs
2. A Helm chart for deploying Spark History Server in Kubernetes

Spark History Server provides a web interface that visualizes information about
completed Spark applications, including event timelines, stages, and executor
metrics.

## Docker Image

### Prerequisites

- Docker installed on your machine
- Git client
- AWS credentials (if accessing logs from S3)

### Building the Docker Image

```shell
git clone https://github.com/kubedai/spark-history-server.git
cd spark-history-server
docker build -t $USER/spark-web-ui:latest .
```

### Running the Docker Container Locally

The repository includes a helper script to simplify running the container
locally. The script supports the following actions:

```shell
sh launch_spark_history_server_locally.sh {start|stop|restart|status|help} [options]
```

#### Example: Starting the container with S3 bucket

```shell
sh launch_spark_history_server_locally.sh start -sb my-bucket -sp spark/history/events
```

#### Options:

- `-sb or --S3_BUCKET`: S3 bucket name (required for start/restart)
- `-sp or --S3_BUCKET_PREFIX`: S3 bucket prefix where event logs are stored (required for start/restart)
- `-r or --AWS_REGION`: AWS Region (default: us-east-1)
- `-cn or --CONTAINER_NAME`: Container name (default: spark-history-server)
- `-du or --DOCKER_USER`: Docker user (default: current user)
- `-ak or --AWS_ACCESS_KEY_ID`: AWS access key (optional if exported as env var)
- `-as or --AWS_SECRET_ACCESS_KEY`: AWS secret key (optional if exported as env var)
- `-at or --AWS_SESSION_TOKEN`: AWS session token (optional if exported as env var)

When started, you can access the Spark History Server at http://localhost:18080

## Helm Chart Deployment

### Prerequisites

- Kubernetes 1.19+
- Helm 3+
- IAM Role for Service Account (IRSA) if using in AWS EKS with S3 bucket access

### Creating IAM Role for Service Account (AWS EKS only)

If deploying on EKS and using S3 for Spark Event logs, you'll need to create an
IAM Role for Service Accounts:

```shell
eksctl create iamserviceaccount \
  --cluster=<eks-cluster-name> \
  --name=spark-history-server \
  --namespace=spark-history-server \
  --attach-policy-arn=arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

### Installing the Helm Chart

Add the repository and update:

```shell
helm repo add kubedai https://kubedai.github.io/spark-history-server
helm repo update
```

Install the chart:

```shell
helm install spark-history-server kubedai/spark-history-server --namespace spark-history-server
```

### Configuration

Before deploying, you'll need to update the `values.yaml` file with:

1. Service account annotations (with IRSA role ARN for AWS EKS)
2. S3 bucket info for Spark event logs

Example values:

```yaml
serviceAccount:
  create: false
  annotations:
    eks.amazonaws.com/role-arn: "<ENTER_IRSA_IAM_ROLE_ARN_HERE>"
  name: "spark-history-server"

sparkHistoryOpts: "-Dspark.history.fs.logDirectory=s3a://<ENTER_S3_BUCKET_NAME>/<PREFIX_FOR_SPARK_EVENT_LOGS>/"
```

### Accessing Spark History Server UI

#### Using port-forward

```shell
kubectl port-forward services/spark-history-server 18085:80 -n spark-history-server
```

Then open a browser and navigate to `http://localhost:18085/`

#### Using Ingress

If you have configured an ingress, you can access the UI through the ingress URL.

### Managing the Helm Release

Upgrade the chart:

```shell
helm upgrade spark-history-server --namespace spark-history-server
```

Uninstall the chart:

```shell
helm uninstall spark-history-server --namespace spark-history-server
```

## Community
Give us a star ⭐️ - If you are using Spark History Server, we would love a star ❤️

## License

This project is licensed under the Apache License 2.0.
