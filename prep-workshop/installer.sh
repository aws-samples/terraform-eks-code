#!/bin/bash

#set -e

# renovate: depName=kubernetes/kubernetes
kubectl_version='1.33.5'

# renovate: depName=helm/helm
helm_version='3.16.4'

# renovate: depName=eksctl-io/eksctl
eksctl_version='0.203.0'

kubeseal_version='0.18.4'

# renovate: depName=mikefarah/yq
yq_version='4.44.6'

# renovate: depName=fluxcd/flux2
flux_version='2.4.0'

# renovate: depName=argoproj/argo-cd
argocd_version='2.13.4'


# renovate: depName=aws/amazon-ec2-instance-selector
ec2_instance_selector_version='2.4.1'

# renovate: depName=hatoo/oha
oha_version='1.4.7'

download () {
  url=$1
  out_file=$2

  curl --location --show-error --silent --output $out_file $url
}

download_and_verify () {
  url=$1
  checksum=$2
  out_file=$3

  curl --location --show-error --silent --output $out_file $url

  echo "$checksum $out_file" > "$out_file.sha256"
  sha256sum --check "$out_file.sha256"

  rm "$out_file.sha256"
}

arch=$(uname -m)
arch_name=""

# Convert to amd64 or arm64
case "$arch" in
  x86_64)
    arch_name="amd64"
    ;;
  aarch64)
    arch_name="arm64"
    ;;
  *)
    echo "Unsupported architecture: $arch"
    exit 1
    ;;
esac
echo "OS tools"
yum install --quiet -y nc git jq zip tar findutils zsh diffutils tree gettext bash-completion python3 python3-pip

pip3 install -q awscurl==0.28 urllib3==1.26.6 &> /dev/null
echo "Other tools"
echo "kubectl"
download "https://dl.k8s.io/release/v$kubectl_version/bin/linux/${arch_name}/kubectl" "kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin

echo "helm"
download "https://get.helm.sh/helm-v$helm_version-linux-${arch_name}.tar.gz" "helm.tar.gz"
tar zxf helm.tar.gz
chmod +x linux-${arch_name}/helm
mv ./linux-${arch_name}/helm /usr/local/bin
rm -rf linux-${arch_name}/ helm.tar.gz

echo "eksctl"
download "https://github.com/eksctl-io/eksctl/releases/download/v${eksctl_version}/eksctl_Linux_${arch_name}.tar.gz" "eksctl.tar.gz"
tar zxf eksctl.tar.gz
chmod +x eksctl
mv ./eksctl /usr/local/bin
rm -rf eksctl.tar.gz

echo "kubeseal"
download "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${kubeseal_version}/kubeseal-${kubeseal_version}-linux-${arch_name}.tar.gz" "kubeseal.tar.gz"
tar xfz kubeseal.tar.gz
chmod +x kubeseal
mv ./kubeseal /usr/local/bin
rm -rf kubeseal.tar.gz

echo "yq"
download "https://github.com/mikefarah/yq/releases/download/v${yq_version}/yq_linux_${arch_name}" "yq"
chmod +x ./yq
mv ./yq /usr/local/bin

echo "flux"
download "https://github.com/fluxcd/flux2/releases/download/v${flux_version}/flux_${flux_version}_linux_${arch_name}.tar.gz" "flux.tar.gz"
tar zxf flux.tar.gz
chmod +x flux
mv ./flux /usr/local/bin
rm -rf flux.tar.gz

echo "argocd"
download "https://github.com/argoproj/argo-cd/releases/download/v${argocd_version}/argocd-linux-${arch_name}" "argocd"
chmod +x ./argocd
mv ./argocd /usr/local/bin/argocd

echo "ec2 instance selector"
download "https://github.com/aws/amazon-ec2-instance-selector/releases/download/v${ec2_instance_selector_version}/ec2-instance-selector-linux-${arch_name}" "ec2-instance-selector"
chmod +x ./ec2-instance-selector
mv ./ec2-instance-selector /usr/local/bin/ec2-instance-selector

echo "oha load generator"
download "https://github.com/hatoo/oha/releases/download/v${oha_version}/oha-linux-${arch_name}" "oha"
chmod +x ./oha
mv ./oha /usr/local/bin


echo "istio cli"
cd /home/ec2-user/environment
rm -rf istio-1.24.3
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.24.3 sh -
chown ec2-user:ec2-user -R istio-1.24.3
export PATH=$HOME/environment/istio-1.24.3/bin:$PATH 
echo "export PATH=$HOME/environment/istio-1.24.3/bin:$PATH" >> ~/.bashrc

echo "kubectl completion"
mkdir -p /home/ec2-user/.bashrc.d
/usr/local/bin/kubectl completion bash >  /home/ec2-user/.bashrc.d/kubectl_completion.bash
echo "alias k=kubectl" >> /home/ec2-user/.bashrc.d/kubectl_completion.bash
echo "complete -F __start_kubectl k" >> /home/ec2-user/.bashrc.d/kubectl_completion.bash
