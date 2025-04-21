# Spark History Server Helm Chart

![Version: 1.1.1](https://img.shields.io/badge/Version-1.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 3.3.4](https://img.shields.io/badge/AppVersion-3.3.4-informational?style=flat-square)

A Helm chart for deploying Spark History Server in Kubernetes to visualize and monitor Spark application metrics.

## TL;DR

```bash
# Install the chart with custom values
helm repo add austinorth https://austinorth.github.io/spark-history-server
helm repo update

helm install spark-history-server austinorth/spark-history-server \
  --namespace spark-history-server \
  --create-namespace \
  --set sparkHistoryOpts="-Dspark.history.fs.logDirectory=s3a://my-bucket/spark-logs/" \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::123456789012:role/SparkHistoryServerRole"
```

## Introduction

This chart deploys Apache Spark History Server on a Kubernetes cluster using the Helm package manager. It's designed to work with AWS S3 for event log storage and includes support for IAM Roles for Service Accounts (IRSA) when deployed on EKS.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- S3 bucket with Spark event logs
- IAM role with S3 read access (if using AWS S3)

## Installing the Chart

### Basic Installation

```bash
helm install spark-history-server austinorth/spark-history-server \
  --namespace spark-history-server \
  --create-namespace
```

### Installation with S3 Configuration

```bash
helm install spark-history-server austinorth/spark-history-server \
  --namespace spark-history-server \
  --set sparkHistoryOpts="-Dspark.history.fs.logDirectory=s3a://my-bucket/spark-logs/"
```

### Installation with Custom Values File

Create a `values.yaml` file:

```yaml
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/SparkHistoryServerRole

sparkHistoryOpts: "-Dspark.history.fs.logDirectory=s3a://my-bucket/spark-logs/"

resources:
  limits:
    cpu: 500m
    memory: 4G
  requests:
    cpu: 200m
    memory: 2G

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: alb
  hosts:
    - host: spark-history.example.com
      paths:
        - /
```

Then install:

```bash
helm install spark-history-server austinorth/spark-history-server \
  -f values.yaml \
  --namespace spark-history-server
```

## Accessing the History Server

### Using Port-Forward

```bash
kubectl port-forward svc/spark-history-server 8080:80 -n spark-history-server
```

Then access: http://localhost:8080

### Using Ingress

If ingress is enabled, access the URL configured in your ingress settings.

## Configuration

The following table lists the configurable parameters of the Spark History Server chart and their default values.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Pod affinity rules |
| fullnameOverride | string | `""` | Override the full name of resources |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"austinorth/spark-history-server"` | Docker image repository |
| imagePullSecrets | list | `[]` | Image pull secrets |
| ingress.annotations | object | `{}` | Annotations for ingress |
| ingress.enabled | bool | `false` | Enable ingress |
| livenessProbe.failureThreshold | int | `3` | Liveness probe failure threshold |
| livenessProbe.httpGet.path | string | `"/"` | Liveness probe HTTP path |
| livenessProbe.httpGet.port | int | `18080` | Liveness probe port |
| nameOverride | string | `""` | Override the name of resources |
| nodeSelector | object | `{}` | Node labels for pod assignment |
| podAnnotations | object | `{}` | Additional pod annotations |
| podLabels | object | `{}` | Additional pod labels |
| podSecurityContext.fsGroup | int | `1000` | Group ID for the pod |
| podSecurityContext.runAsUser | int | `1000` | User ID to run the container |
| replicaCount | int | `1` | Number of replicas |
| resources.limits.cpu | string | `"200m"` | CPU limit |
| resources.limits.memory | string | `"2G"` | Memory limit |
| resources.requests.cpu | string | `"100m"` | CPU request |
| resources.requests.memory | string | `"1G"` | Memory request |
| securityContext | object | `{...}` | Security context for the container |
| service.externalPort | int | `80` | External service port |
| service.internalPort | int | `18080` | Internal container port |
| service.type | string | `"ClusterIP"` | Kubernetes service type |
| serviceAccount.create | bool | `true` | Create a service account |
| serviceAccount.name | string | `"spark-history-server-sa"` | Service account name |
| serviceAccount.annotations | object | `{}` | Annotations for the service account (e.g., IRSA role ARN) |
| sparkConf | string | `"spark.hadoop.fs.s3a.aws.credentials.provider=com.amazonaws.auth.WebIdentityTokenCredentialsProvider\n..."` | Spark configuration properties |
| sparkHistoryOpts | string | `""` | Spark history server options (e.g., log directory location) |
| tolerations | list | `[]` | Pod tolerations |
| extraVolumes | list | `[]` | List of extra volume definitions (Kubernetes YAML format) to add to the pod specification. |
| extraVolumeMounts | list | `[]` | List of extra volume mount definitions (Kubernetes YAML format) to add to the main container. |

## AWS S3 Integration

To configure Spark History Server to read logs from S3:

1. Create an IAM Role with S3 read access
2. Set up IRSA if using EKS:
   ```bash
   eksctl create iamserviceaccount \
     --cluster=your-cluster \
     --name=spark-history-server-sa \
     --namespace=spark-history-server \
     --attach-policy-arn=arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
     --approve
   ```
3. Configure the Helm values:
   ```yaml
   serviceAccount:
     create: true
     name: "spark-history-server-sa"
     annotations:
       eks.amazonaws.com/role-arn: "your-role-arn"

   sparkHistoryOpts: "-Dspark.history.fs.logDirectory=s3a://your-bucket/spark-logs/"
   ```

## Uninstalling the Chart

```bash
helm uninstall spark-history-server -n spark-history-server
```
