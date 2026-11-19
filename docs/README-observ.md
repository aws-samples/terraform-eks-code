# observ Stage Documentation

## Overview

The `observ` stage deploys metrics and tracing for the EKS cluster using **v3 of the AWS Observability Accelerator** `eks-monitoring` module with the `self-managed-amp` collector profile. It creates an Amazon Managed Prometheus (AMP) workspace, an OpenTelemetry Collector in the cluster that writes metrics to AMP and traces to AWS X-Ray, and dashboards in an Amazon Managed Grafana (AMG) workspace.

**Execution Time**: ~5-10 minutes
**Dependencies**: tf-setup, net, cluster, nodepool, addons (requires a running cluster)
**Outputs**: Grafana workspace, Prometheus workspace, OTel Collector, dashboards, Prometheus rules
**Purpose**: Metrics (AMP) and traces (X-Ray) for EKS, visualised in Grafana

Container logs are not handled here: the CloudWatch Observability add-on installed by the `addons` stage already ships them to CloudWatch (Container Insights), so `enable_logs = false`.

---

## Architecture Overview

```
┌──────────────────────────── EKS cluster ─────────────────────────────┐
│                                                                       │
│  kube-state-metrics ─┐                                                │
│  node-exporter ──────┼──► OpenTelemetry Collector ──► AMP remote write │
│  kubelet / cAdvisor ─┘    (namespace otel-collector)   (SigV4, IRSA)   │
│                                │                                      │
│  apps (OTLP traces) ───────────┴──────────────────► AWS X-Ray          │
└───────────────────────────────────────────────────────────────────────┘

Amazon Managed Grafana (workspace "keycloak-blog")
  ├─ Data source "Amazon Managed Prometheus" (SigV4, workspace IAM role)
  └─ Folder "EKS Monitoring": cluster, kubelet, namespace-workloads,
                              node-exporter, nodes, workloads dashboards
```

What v3 no longer deploys (all were part of v2): FluxCD, Grafana Operator, External Secrets Operator, the ADOT operator and cert-manager. Dashboards are created directly by Terraform through the Grafana provider.

---

## Key Components

### 1. AWS Observability Accelerator `eks-monitoring` module (v3)

```terraform
source = "github.com/aws-observability/terraform-aws-observability-accelerator//modules/eks-monitoring?ref=4c39cde"
```

- v3 is not yet tagged upstream (the newest release is v2.13.1), so the module is **pinned to commit `4c39cde`** on `main` (2026-04-24) rather than tracking the branch.
- `collector_profile = "self-managed-amp"`. The other profiles are `managed-metrics` (agentless AMP scraper, no traces) and `cloudwatch-otlp` (installs the CloudWatch Observability chart, which would clash with the add-on from the `addons` stage).
- Requires the helm provider >= 3.0, the `grafana/grafana` provider and `hashicorp/http` (all pinned via `backend-observ.tf`).

### 2. Amazon Managed Prometheus (AMP)

- Workspace alias `eks-monitoring`, created by the module.
- Recording and alerting rule groups created by the module (`aws_prometheus_rule_group_namespace`).
- The collector writes with SigV4 using an IRSA role `<cluster>-otel-collector`.

### 3. OpenTelemetry Collector

- Helm chart `open-telemetry/opentelemetry-collector`, namespace `otel-collector`.
- Scrape jobs: `kubelet`, `kubelet-cadvisor`, `kube-state-metrics`, `node-exporter`.
- Pipelines: `metrics` → AMP, `traces` → X-Ray.

**Workarounds for two v3 bugs** (in `observ/main.tf`, remove once fixed upstream):

| Setting | Why |
|---|---|
| `otel_collector_chart_version = "0.107.0"` | The module sets `exporters.logging = null`. With the module's default chart (0.114.0, collector 0.118) the null key stays in the rendered config, and collectors >= 0.111 refuse to start because the `logging` exporter was removed. Chart 0.107.0 = collector 0.110.0. |
| `helm_values = { "config.service.pipelines.logs" = "null" }` | With `enable_logs = false` the module adds no logs pipeline, so the chart's default one is kept. It references `memory_limiter` and `debug`, which the module removes, and the collector refuses to start. Setting it to `null` removes the chart default. |

**Known limitation**: node-exporter is scraped through its Service name, so each scrape lands on one random node and all nodes report under a single `instance` label.

### 4. Amazon Managed Grafana (AMG)

- Workspace `keycloak-blog` (`grafana.tf`), Grafana 10.4, `authentication_providers = ["SAML"]`. SAML (Keycloak) must be configured before anyone can log in to the UI.
- Workspace IAM role `grafana-assume` with `AmazonPrometheusQueryAccess`, `AmazonGrafanaCloudWatchAccess` and `AWSXrayReadOnlyAccess`.
- API key `observability-key` (`grafana-key.tf`), role ADMIN, `seconds_to_live = 432000` (5 days). The Grafana provider uses it to create the folder, dashboards and data source. **After it expires, plans in this stage fail** until the key is recreated (`terraform apply -replace=aws_grafana_workspace_api_key.key`).

### 5. Grafana data source for AMP

The AMP profiles only output the data source settings (`amp_datasource_config`), so `main.tf` creates it:

```terraform
resource "grafana_data_source" "amp" {
  type       = module.eks_monitoring.amp_datasource_config.type
  name       = "Amazon Managed Prometheus"
  url        = module.eks_monitoring.amp_datasource_config.endpoint
  is_default = true
  json_data_encoded = jsonencode({
    httpMethod    = module.eks_monitoring.amp_datasource_config.http_method
    sigV4Auth     = true
    sigV4AuthType = "ec2_iam_role" # Amazon Managed Grafana workspace IAM role
    sigV4Region   = module.eks_monitoring.amp_datasource_config.sigv4_region
  })
}
```

---

## File-by-File Breakdown

| File | Purpose |
|---|---|
| `main.tf` | Kubernetes, helm (v3 syntax) and Grafana providers; `eks_monitoring` module call; AMP Grafana data source |
| `grafana.tf` | AMG workspace and its IAM role / policy attachments |
| `grafana-key.tf` | AMG API key used by the Grafana provider |
| `backend-observ.tf` | S3 backend and provider versions (symlink to `tf-setup/generated/`) |
| `data-params-cluster.tf`, `data-params-setup.tf`, `aws-data.tf`, `vars-main.tf` | Shared lookups and variables (symlinks to `common-files/`) |
| `.terraform.lock.hcl` | Provider lock file (committed) |

### Provider configuration (helm provider 3)

```terraform
provider "helm" {
  kubernetes = {
    host                   = data.aws_ssm_parameter.endpoint.value
    cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
    }
  }
}

provider "grafana" {
  url  = format("https://%s", aws_grafana_workspace.workshop.endpoint)
  auth = aws_grafana_workspace_api_key.key.key
}
```

---

## Dashboards

Created in the Grafana folder **EKS Monitoring**, fetched at plan time from `aws-observability/aws-observability-accelerator` (`artifacts/grafana-dashboards/eks/infrastructure`, ref `main`):

- Kubernetes / Compute Resources / Cluster
- Kubelet
- Namespace (Workloads)
- Node Exporter / Nodes
- Nodes
- Workloads

Because the dashboards come from the upstream `main` branch, they can change between plans. Set `dashboard_git_ref` in the module call to pin them.

---

## Verification

```bash
# Collector, kube-state-metrics, node-exporter
kubectl get pods -n otel-collector
kubectl get pods -n kube-system -l app.kubernetes.io/name=kube-state-metrics
kubectl get pods -n prometheus-node-exporter

# Collector logs (should show no errors or export failures)
kubectl logs -n otel-collector deploy/otel-collector-opentelemetry-collector -c opentelemetry-collector --since=10m

# AMP workspace
aws amp list-workspaces --query 'workspaces[].[workspaceId,alias,status.statusCode]' --output text

# Grafana endpoint
terraform state show aws_grafana_workspace.workshop | grep endpoint
```

### Example PromQL (Grafana Explore, data source "Amazon Managed Prometheus")

```promql
# Scrape targets up, by job
count by (job) (up)

# Node CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Pod memory working set by namespace
sum by (namespace) (container_memory_working_set_bytes{container!=""})

# Pod restarts
sum by (namespace, pod) (kube_pod_container_status_restarts_total)
```

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Collector `CrashLoopBackOff`: "the logging exporter has been deprecated" | Collector chart newer than 0.107.0 with this module commit. Keep `otel_collector_chart_version = "0.107.0"`. |
| Collector `CrashLoopBackOff`: "references processor memory_limiter which is not configured" | The chart's default logs pipeline is still present. Keep the `config.service.pipelines.logs = null` `helm_values` entry while `enable_logs = false`. |
| Plan fails with Grafana 401 errors | The API key expired (5-day TTL). Run `terraform apply -replace=aws_grafana_workspace_api_key.key`. |
| Dashboards show no data | Check that the `Amazon Managed Prometheus` data source exists and the collector logs show no `Exporting failed` errors. |
| Collector pod has extra `opentelemetry-auto-instrumentation-*` init containers | Added by the CloudWatch add-on's Application Signals auto-instrumentation. Harmless. |

---

## Upgrading from v2 (what was done)

1. `terraform destroy -target=module.eks_monitoring` with the v2 code, so the v2 resources were removed by the providers that created them.
2. Deleted the empty namespaces (`flux-system`, `grafana-operator`, `prometheus-node-exporter`) and the Grafana Operator CRDs that Helm leaves behind.
3. Switched `gen-backend.sh` to helm `~> 3.3.0` for every stage and regenerated the backend files.
4. Replaced the module call with the v3 one above and applied.

---

## Destroying This Stage

```bash
cd observ
terraform destroy
```

Destroy this stage before `addons`, `nodepool` and `cluster`.
