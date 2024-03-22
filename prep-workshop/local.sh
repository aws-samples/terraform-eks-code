
export REPOSITORY_OWNER="aws-samples"
export REPOSITORY_NAME="eks-workshop-v2"
export REPOSITORY_REF="main"
REPOSITORY_OWNER=${REPOSITORY_OWNER:-"aws-samples"}
REPOSITORY_NAME=${REPOSITORY_NAME:-"eks-workshop-v2"}

cat << EOT > /usr/local/bin/reset-environment
#!/bin/bash
#set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/reset-environment | bash -s -- \$1
EOT
  chmod +x /usr/local/bin/reset-environment
  cat << EOT > /usr/local/bin/delete-environment
#!/bin/bash
#set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/delete-environment | bash
EOT
  chmod +x /usr/local/bin/delete-environment
  cat << EOT > /usr/local/bin/wait-for-lb
#!/bin/bash
#set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/wait-for-lb | bash -s -- \$1
EOT
  chmod +x /usr/local/bin/wait-for-lb
  cat << EOT > /usr/local/bin/use-cluster
#!/bin/bash
#set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/use-cluster | bash -s -- \$1
EOT
  chmod +x /usr/local/bin/use-cluster
  cat << EOT > /usr/local/bin/awshttp
#!/bin/bash
#set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/awshttp | bash -s -- \$1
EOT
  chmod +x /usr/local/bin/awshttp
  cat << EOT > /usr/local/bin/delete-all-if-crd-exists
#!/bin/bash
#set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/delete-all-if-crd-exists | bash -s -- \$@
EOT
  chmod +x /usr/local/bin/delete-all-if-crd-exists
  cat << EOT > /usr/local/bin/delete-all-and-wait-if-crd-exists
#!/bin/bash
#set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/delete-all-and-wait-if-crd-exists | bash -s -- \$@
EOT
  chmod +x /usr/local/bin/delete-all-and-wait-if-crd-exists
  cat << EOT > /usr/local/bin/delete-nodegroup
#!/bin/bash
#set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/delete-nodegroup | bash -s -- \$1
EOT
  chmod +x /usr/local/bin/delete-nodegroup
  cat << EOT > /usr/local/bin/uninstall-helm-chart
#!/bin/bash
#set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/uninstall-helm-chart | bash -s -- \$@
EOT
  chmod +x /usr/local/bin/uninstall-helm-chart
  cat << EOT > /usr/local/bin/update-ide
#!/bin/bash
#set -e
curl -fsSL https://raw.githubusercontent.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/$REPOSITORY_REF/lab/bin/update-ide | bash
EOT
  chmod +x /usr/local/bin/update-ide
