# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

[settings.kubernetes]
api-server = "${ cluster_endpoint }"
cluster-certificate = "${ cluster_ca_certificate }"
cluster-name = "${ cluster_name }"