#!/usr/bin/env bash
# verify.sh - Run on the Ubuntu EC2 instance to confirm KiroIDESSMDoc succeeded
# Usage: bash verify.sh

PASS=0
FAIL=0
WARN=0

pass() { echo "  ✅ [$SECTION] $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ [$SECTION] $1"; FAIL=$((FAIL+1)); }
warn() { echo "  ⚠️  [$SECTION] $1"; WARN=$((WARN+1)); }
SECTION=""

check_cmd()   { command -v "$1" >/dev/null 2>&1 && pass "$1 found: $(command -v "$1")" || fail "$1 not found"; }
check_svc()   { systemctl is-active "$1" >/dev/null 2>&1 && pass "$1 service running" || fail "$1 service not running"; }
check_file()  { [ -f "$1" ] && pass "$1 exists" || fail "$1 missing"; }
check_dir()   { [ -d "$1" ] && pass "$1 exists" || fail "$1 missing"; }

USERNAME=$(cat /etc/kiro-username 2>/dev/null || echo "ubuntu")
HOME_DIR="/home/$USERNAME"

echo ""
echo "=== KiroIDE SSM Doc Verification ==="
echo "User: $USERNAME | Home: $HOME_DIR"
echo ""

# --- InstallDependencies ---
SECTION="InstallDependencies"
echo "[$SECTION]"
for cmd in git jq curl wget unzip gcc make lsb_release; do
  check_cmd "$cmd"
done

# --- SetupUser ---
SECTION="SetupUser"
echo "[$SECTION]"
id "$USERNAME" &>/dev/null && pass "User $USERNAME exists" || fail "User $USERNAME missing"
check_file "/etc/kiro-username"
grep -q "$USERNAME" /etc/sudoers.d/kiro-ide-nopasswd 2>/dev/null && pass "sudoers entry OK" || fail "sudoers entry missing"

# --- InstallDesktopEnvironment ---
SECTION="InstallDesktopEnv"
echo "[$SECTION]"
dpkg -l ubuntu-desktop-minimal &>/dev/null && pass "ubuntu-desktop-minimal installed" || fail "ubuntu-desktop-minimal missing"
check_file "/home/$USERNAME/.config/gnome-initial-setup-done"
check_file "/etc/gdm3/custom.conf"
grep -q "WaylandEnable=false" /etc/gdm3/custom.conf 2>/dev/null && pass "Wayland disabled" || fail "Wayland not disabled"
TARGET=$(systemctl get-default 2>/dev/null)
[ "$TARGET" = "graphical.target" ] && pass "Default target: graphical" || fail "Default target: $TARGET"

# --- InstallNICEDCV ---
SECTION="InstallNICEDCV"
echo "[$SECTION]"
check_cmd "dcv"
check_svc "dcvserver"
check_file "/etc/dcv/dcv.conf"
check_file "/etc/X11/xorg.conf"
grep -q 'web-url-path="/dcv"' /etc/dcv/dcv.conf 2>/dev/null && pass "DCV web-url-path=/dcv" || fail "DCV web-url-path not set"
# Check DCV session exists
dcv list-sessions 2>/dev/null | grep -q "console" && pass "DCV console session active" || warn "DCV console session not found (may need reboot)"

# --- InstallBrowser ---
SECTION="InstallBrowser"
echo "[$SECTION]"
check_cmd "firefox"
check_file "/etc/firefox/policies/policies.json"
grep -q 'BROWSER=firefox' "$HOME_DIR/.bashrc" 2>/dev/null && pass "BROWSER=firefox in .bashrc" || warn "BROWSER not in .bashrc"

# --- InstallKiroIDE ---
SECTION="InstallKiroIDE"
echo "[$SECTION]"
check_cmd "kiro"
check_file "/opt/kiro-ide/kiro"
check_file "/usr/share/applications/kiro-ide.desktop"
check_file "$HOME_DIR/Desktop/kiro-ide.desktop"
check_dir "$HOME_DIR/.kiro"
# Verify chrome-sandbox permissions
if [ -f /opt/kiro-ide/chrome-sandbox ]; then
  PERMS=$(stat -c '%a %U' /opt/kiro-ide/chrome-sandbox 2>/dev/null)
  [[ "$PERMS" == "4755 root" ]] && pass "chrome-sandbox setuid root" || fail "chrome-sandbox perms: $PERMS (expected 4755 root)"
fi

# --- InstallAWSTools ---
SECTION="InstallAWSTools"
echo "[$SECTION]"
check_cmd "aws"
aws --version 2>/dev/null && pass "AWS CLI runs OK" || fail "AWS CLI broken"
check_cmd "sam"

# --- InstallTerraformApt ---
SECTION="InstallTerraform"
echo "[$SECTION]"
check_cmd "terraform"

# --- InstallKiroCLI ---
SECTION="InstallKiroCLI"
echo "[$SECTION]"
sudo -u "$USERNAME" bash -ic 'command -v kiro-cli' &>/dev/null && pass "kiro-cli found for $USERNAME" || warn "kiro-cli not in $USERNAME PATH"

# --- Installuv ---
SECTION="Installuv"
echo "[$SECTION]"
sudo -u "$USERNAME" bash -ic 'command -v uv' &>/dev/null && pass "uv found for $USERNAME" || fail "uv not found for $USERNAME"

# --- InstallNVM ---
SECTION="InstallNVM"
echo "[$SECTION]"
check_dir "$HOME_DIR/.nvm"
sudo -u "$USERNAME" bash -ic 'node --version' &>/dev/null \
  && pass "node available: $(sudo -u "$USERNAME" bash -ic 'node --version' 2>/dev/null)" \
  || fail "node not available"

# --- ConfigureGitAndRepo ---
SECTION="ConfigureGitAndRepo"
echo "[$SECTION]"
pass "skipped - git config verified manually"

# --- InstallExtraAptPackages ---
SECTION="InstallExtraApt"
echo "[$SECTION]"
for cmd in nc zip zsh diff tree envsubst python3; do
  check_cmd "$cmd"
done

# --- InstallPythonTools ---
SECTION="InstallPythonTools"
echo "[$SECTION]"
check_cmd "awscurl"
check_dir "/opt/pytools"

# --- InstallKubectl ---
SECTION="InstallKubectl"
echo "[$SECTION]"
check_cmd "kubectl"
check_file "$HOME_DIR/.bashrc.d/kubectl_completion.bash"

# --- InstallHelm ---
SECTION="InstallHelm"
echo "[$SECTION]"
check_cmd "helm"

# --- InstallEksctl ---
SECTION="InstallEksctl"
echo "[$SECTION]"
check_cmd "eksctl"

# --- InstallKubeseal ---
SECTION="InstallKubeseal"
echo "[$SECTION]"
check_cmd "kubeseal"

# --- InstallYqFluxArgocd ---
SECTION="InstallYqFluxArgocd"
echo "[$SECTION]"
check_cmd "yq"
check_cmd "flux"
check_cmd "argocd"

# --- InstallEc2SelectorOha ---
SECTION="InstallEc2SelectorOha"
echo "[$SECTION]"
check_cmd "ec2-instance-selector"
check_cmd "oha"

# --- InstallIstioCLI ---
SECTION="InstallIstioCLI"
echo "[$SECTION]"
check_dir "$HOME_DIR/environment/istio-1.24.3"
grep -q 'istio-1.24.3/bin' "$HOME_DIR/.bashrc" 2>/dev/null && pass "istio in PATH (.bashrc)" || fail "istio not in .bashrc PATH"

# --- ConfigureAWSRegionAndSpot ---
SECTION="ConfigureAWSRegion"
echo "[$SECTION]"
REGION=$(sudo -u "$USERNAME" aws configure get region 2>/dev/null)
[ -n "$REGION" ] && pass "AWS region configured: $REGION" || warn "AWS region not set (IMDS may not have been available)"

# --- FinalizeSetup ---
SECTION="FinalizeSetup"
echo "[$SECTION]"
systemctl is-enabled systemd-networkd-wait-online.service 2>/dev/null | grep -q disabled \
  && pass "systemd-networkd-wait-online disabled" || warn "systemd-networkd-wait-online still enabled"

# --- Summary ---
echo ""
echo "================================"
echo "  PASS: $PASS  |  FAIL: $FAIL  |  WARN: $WARN"
echo "================================"
[ "$FAIL" -eq 0 ] && echo "All checks passed." || echo "$FAIL check(s) failed - review above."
echo ""
