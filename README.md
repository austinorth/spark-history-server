[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/spark-history-server)](https://artifacthub.io/packages/search?repo=spark-history-server)
[![Docker Image](https://img.shields.io/docker/v/austinorth/spark-history-server/v3.3.4?label=docker&logo=docker)](https://hub.docker.com/repository/docker/austinorth/spark-history-server/tags/v3.3.4)

# Spark History Server

A Helm chart and Docker container for deploying Spark History Server (Spark Web UI) to monitor the metrics and performance of your Spark jobs.

## Overview

This project provides two main components:

1. **Docker Image**: A ready-to-use Docker image for Spark History Server configured to read Spark Event Logs from S3
2. **Helm Chart**: A Kubernetes Helm chart for easy deployment of Spark History Server on Kubernetes clusters

The Spark History Server provides a web interface that visualizes information about completed Spark applications, including event timelines, stages, tasks, and executor metrics, helping you diagnose and troubleshoot Spark job performance.

## Quick Start

### Using the Helm Chart

```bash
# Add the Helm repository
helm repo add austinorth https://austinorth.github.io/spark-history-server
helm repo update

# Install the chart with your S3 bucket information
helm install spark-history-server austinorth/spark-history-server \
  --namespace spark-history-server \
  --create-namespace \
  --set sparkHistoryOpts="-Dspark.history.fs.logDirectory=s3a://YOUR-BUCKET/spark-event-logs/" \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="YOUR-IRSA-ROLE-ARN"
```

For detailed chart configuration options, see the [Helm Chart README](charts/spark-history-server/README.md).

### Using the Docker Image

```bash
# Run the Docker container with S3 access
docker run -d -p 18080:18080 \
  -e SPARK_HISTORY_OPTS="-Dspark.history.fs.logDirectory=s3a://YOUR-BUCKET/spark-event-logs/ \
  -Dspark.hadoop.fs.s3a.access.key=YOUR_AWS_ACCESS_KEY \
  -Dspark.hadoop.fs.s3a.secret.key=YOUR_AWS_SECRET_KEY" \
  austinorth/spark-history-server
```

## Docker Image Details

The provided Docker image:
- Based on Amazon Corretto 8 with Maven 3.6
- Includes Spark 3.3.2 (without Hadoop)
- Configured with required AWS/S3 dependencies
- Default port: 18080

### Building the Docker Image Locally

```bash
git clone https://github.com/austinorth/spark-history-server.git
cd spark-history-server
docker build -t your-username/spark-history-server:latest .
```

### Helper Script for Local Testing

The repository includes a convenient script for running Spark History Server locally:

```bash
# Start the server pointing to your S3 bucket
sh launch_spark_history_server_locally.sh start -sb your-bucket-name -sp path/to/events
```

Run `sh launch_spark_history_server_locally.sh help` for all available options.

## Helm Chart Details

The Helm chart provides:
- Easy configuration for S3 event log sources
- AWS IAM Role for Service Account (IRSA) support
- Customizable resource requests and limits
- Ingress support for exposing the service
- Readiness and liveness probes

For complete configuration options, see the [Helm Chart README](charts/spark-history-server/README.md).

## AWS IAM Setup

If deploying in AWS EKS with S3 access:

1. Create an IAM policy for S3 read access to your event logs bucket
2. Create an IAM role for service account (IRSA):

```bash
eksctl create iamserviceaccount \
  --cluster=your-eks-cluster \
  --name=spark-history-server \
  --namespace=spark-history-server \
  --attach-policy-arn=arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --approve
```

## Community
Give us a star ⭐️ - If you are using Spark History Server, we would love a star ❤️

## License

This project is licensed under the Apache License 2.0.
