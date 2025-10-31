sudo su -
# as root
### InstallAWSCLI
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl unzip
curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip -o /tmp/aws-cli.zip
unzip -q -d /tmp /tmp/aws-cli.zip
sudo /tmp/aws/install
rm -rf /tmp/aws
aws --version
### InstallDocker
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \"deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu {{ ubuntuVersion }} stable\" >>/etc/apt/sources.list.d/docker.list
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker ubuntu
docker --version
#
###InstallGit
#
add-apt-repository ppa:git-core/ppa
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y git
sudo -u ubuntu git config --global user.email \"participant@workshops.aws\"
sudo -u ubuntu git config --global user.name \"Workshop Participant\"
sudo -u ubuntu git config --global init.defaultBranch \"main\"
git --version
#
### Install Node
#
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource-keyring.gpg
echo \"deb [arch={{ architecture }} signed-by=/usr/share/keyrings/nodesource-keyring.gpg] https://deb.nodesource.com/{{ nodeVersion }} {{ ubuntuVersion }} main\" >>/etc/apt/sources.list.d/nodesource.list
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
#
### Install Python
#
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip python3.10-venv python3-boto3 python3-pytest
echo 'alias pytest=pytest-3' >>/home/ubuntu/.bashrc
python3 --version
pip3 --version
#
## CodeCommit repo
#!/bin/bash
pip3 install git-remote-codecommit
if [[ -z \"\" ]]; then
    echo \"No Code Commit Repo to clone\"
else
    mkdir -p /Workshop
    sudo chown ubuntu:ubuntu /Workshop -R
    cd /Workshop # move to the directory above where we want to clone the repo
    if [[ -d \"../\" ]]; then
        cd ..
    fi
    echo 'Cloning codecommit::eu-west-2:// into $PWD/'
    sudo -u ubuntu git clone -q codecommit::eu-west-2://
fi
###      InstallPythonRequirements
#!/bin/bash
mkdir -p /Workshop
sudo chown ubuntu:ubuntu /Workshop -R
cd /Workshop
if [[ -z \"\" ]]; then
    if [[ -d \"\" ]]; then
        cd
    fi
fi
python3 -m venv .venv
source .venv/bin/activate
if [[ -f \"requirements.txt\" ]]; then
    echo 'installing requirements.txt'
    pip3 install -r requirements.txt
fi
deactivate
sudo chown ubuntu:ubuntu .venv -R
#
### Update Profile
#
#!/bin/bash
echo LANG=en_US.utf-8 >>/etc/environment
echo LC_ALL=en_US.UTF-8 >>/etc/environment
echo 'PATH=$PATH:/home/ubuntu/.local/bin' >>/home/ubuntu/.bashrc
echo 'export PATH' >>/home/ubuntu/.bashrc
echo 'export AWS_REGION=eu-west-2' >>/home/ubuntu/.bashrc
echo 'export AWS_ACCOUNTID=566972129213' >>/home/ubuntu/.bashrc
echo 'export NEXT_TELEMETRY_DISABLED=1' >>/home/ubuntu/.bashrc
##
###ConfigureCodeServer
##
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl nginx
#!/bin/bash
export HOME=/home/ubuntu
curl -fsSL https://code-server.dev/install.sh | sh
sudo systemctl enable --now code-server@ubuntu
sudo tee /etc/nginx/sites-available/code-server <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name dzsbw2uvbu9tr.cloudfront.net;
    location / {
      proxy_pass http://localhost:8080/;
      proxy_set_header Host \\$host;
      proxy_set_header Upgrade \\$http_upgrade;
      proxy_set_header Connection upgrade;
      proxy_set_header Accept-Encoding gzip;
    }
    location /app {
      proxy_pass http://localhost:8081/app;
      proxy_set_header Host \\$host;
      proxy_set_header Upgrade \\$http_upgrade;
      proxy_set_header Connection upgrade;
      proxy_set_header Accept-Encoding gzip;
    }
}
EOF
sudo tee /home/ubuntu/.config/code-server/config.yaml <<EOF
cert: false
auth: password
hashed-password: \"$(echo -n $(aws sts get-caller-identity --query \"Account\" --output text) | sudo npx argon2-cli -e)\"
EOF
sudo -u ubuntu --login mkdir -p /home/ubuntu/.local/share/code-server/User/
sudo -u ubuntu --login touch /home/ubuntu/.local/share/code-server/User/settings.json
sudo tee /home/ubuntu/.local/share/code-server/User/settings.json <<EOF
\n{\n  \"extensions.autoUpdate\": false,\n  \"extensions.autoCheckUpdates\": false,\n  \"terminal.integrated.cwd\": \"/Workshop\\n  \"telemetry.telemetryLevel\": \"off\\n  \"security.workspace.trust.startupPrompt\": \"never\\n  \"security.workspace.trust.enabled\": false,\n  \"security.workspace.trust.banner\": \"never\\n  \"security.workspace.trust.emptyWindow\": false,\n  \"editor.indentSize\": \"tabSize\\n  \"editor.tabSize\": 2,\n  \"python.testing.pytestEnabled\": true,\n  \"auto-run-command.rules\": [\n    {\n      \"command\": \"workbench.action.terminal.new\"\n    }\n  ]\n}
EOF
sudo systemctl restart code-server@ubuntu
sudo ln -s ../sites-available/code-server /etc/nginx/sites-enabled/code-server
sudo systemctl restart nginx
sudo -u ubuntu --login code-server --install-extension AmazonWebServices.amazon-q-vscode --force
sudo -u ubuntu --login code-server --install-extension synedra.auto-run-command --force
sudo -u ubuntu --login code-server --install-extension vscjava.vscode-java-pack --force
sudo -u ubuntu --login code-server --install-extension ms-vscode.live-server --force
sudo chown ubuntu:ubuntu /home/ubuntu -R
##
### Install CDK
npm install -g aws-cdk
cdk --version
##
### InstallGo
##
add-apt-repository ppa:longsleep/golang-backports
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y golang-go
sudo chown ubuntu:ubuntu /home/ubuntu -R
go version

#
###  InstallRust
#
add-apt-repository ppa:ubuntu-mozilla-security/rust-next
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y rustc cargo
sudo chown ubuntu:ubuntu /home/ubuntu -R
rustc --version
#
### InstallDotnet
#
apt-get update && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y {{ dotNetVersion }}
sudo dotnet tool install -g Microsoft.Web.LibraryManager.Cli
export PATH=\"$PATH:/home/ubuntu/.dotnet/tools\"
sudo chown ubuntu:ubuntu /home/ubuntu -R
dotnet --list-sdks
#
### InstallJava
#
apt-get update && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y wget
wget -O- https://apt.corretto.aws/corretto.key | sudo apt-key add -
sudo add-apt-repository 'deb https://apt.corretto.aws stable main' -y
DEBIAN_FRONTEND=noninteractive sudo apt-get update
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y java-17-amazon-corretto-jdk java-1.8.0-amazon-corretto-jdk maven
echo 'export JAVA_1_8_HOME=$(dirname $(dirname $(readlink -f $(which java))))' >>/home/ubuntu/.bashrc
echo 'export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))' >>/home/ubuntu/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin:/usr/share/maven/bin' >>/home/ubuntu/.bashrc
java -version
mvn --version
update-alternatives --list java
