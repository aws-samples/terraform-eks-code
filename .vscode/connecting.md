# Connecting to the IDE instance with SSM port forwarding

`deploy-stack.sh` creates a code-server (VS Code in the browser) instance in a **private subnet** of the default VPC. It has no public IP and no inbound rules from the internet. AWS Systems Manager (SSM) Session Manager lets you reach it from your laptop without opening any ports: the SSM agent on the instance connects out to SSM, and your local AWS CLI tunnels a local port through that connection.

This is the private way in. The alternative, `cre-origin.sh`, publishes code-server through CloudFront to the internet; you don't need it if you use port forwarding.

## What runs on the instance

| Port (on the instance) | Listens on | What it is |
|---|---|---|
| 8080 | `127.0.0.1` only | code-server itself, password login. **Forward this one.** |
| 8081 | `127.0.0.1` | Optional dev server for an app you run in the IDE (served at `/app` through nginx) |
| 80 | all interfaces | nginx, used only by the CloudFront path. It only answers `*.cloudfront.net` host names, so a forward to port 80 shows the nginx test page, not code-server. |

| Setting | Value (stack defaults) |
|---|---|
| Stack | `vscode` |
| Region | `eu-west-1` |
| Instance Name tag | `eksworkshop-kiroide` |
| Linux user | `ec2-user` |
| Workspace folder | `/home/ec2-user/environment` |
| Password | stack output `Password` (random, 16 characters) |

## Prerequisites (on your laptop)

1. **AWS CLI v2** with credentials for the account (`aws sts get-caller-identity` works).
2. **Session Manager plugin** for the AWS CLI:
   - macOS: `brew install --cask session-manager-plugin`
   - Linux / Windows / manual install: [Install the Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
   - Check: `session-manager-plugin --version`
3. **IAM permissions** for your identity:
   - `ssm:StartSession` on the instance and on the `AWS-StartPortForwardingSession` document (and `AWS-StartPortForwardingSessionToRemoteHost` if you use the remote-host example below)
   - `ssm:TerminateSession` / `ssm:ResumeSession` on your own sessions
   - `ec2:DescribeInstances`, `ssm:DescribeInstanceInformation`, `cloudformation:DescribeStacks`

Nothing extra is needed on the instance: its role has `AmazonSSMManagedInstanceCore`, and the stack creates VPC endpoints for `ssm`, `ssmmessages` and `ec2messages`.

## Connect

```bash
export AWS_REGION=eu-west-1

# 1. Instance ID
IID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=eksworkshop-kiroide" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)
echo "$IID"

# 2. Check SSM can reach it (expect: Online). A new instance can take a few minutes.
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$IID" \
  --query 'InstanceInformationList[0].PingStatus' --output text

# 3. code-server password
aws cloudformation describe-stacks --stack-name vscode \
  --query "Stacks[0].Outputs[?OutputKey=='Password'].OutputValue" --output text

# 4. Forward local port 8080 to code-server on the instance (leave this running)
aws ssm start-session --target "$IID" \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["8080"],"localPortNumber":["8080"]}'
```

When the session prints `Waiting for connections...`, open:

```
http://localhost:8080/?folder=/home/ec2-user/environment
```

and log in with the password from step 3.

If local port 8080 is already in use, pick another local port, for example `"localPortNumber":["18080"]`, and open `http://localhost:18080/...` instead.

### Dev server (optional)

If you run an app on port 8081 inside the IDE, forward it in a second terminal:

```bash
aws ssm start-session --target "$IID" \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["8081"],"localPortNumber":["8081"]}'
```

### Reaching something inside the VPCs through the instance

`AWS-StartPortForwardingSessionToRemoteHost` uses the instance as a jump host to any address it can reach. For example, once the workshop's `net` and `sampleapp` stages are built, the IDE VPC is peered with the EKS VPC and the sample app's **internal** NLB is reachable from the instance:

```bash
UI_NLB=$(kubectl get svc -n sampleapp ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

aws ssm start-session --target "$IID" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"$UI_NLB\"],\"portNumber\":[\"80\"],\"localPortNumber\":[\"9080\"]}"
# then open http://localhost:9080/
```

The same works for the Istio gateway's internal NLB (`kubectl get svc -n istio-ingress istio-ingress`, path `/productpage`).

### A shell on the instance

```bash
aws ssm start-session --target "$IID"
sudo su - ec2-user
```

## Disconnect

Press `Ctrl+C` in the terminal running the port-forward session. To end a session from elsewhere:

```bash
aws ssm describe-sessions --state Active --query 'Sessions[].[SessionId,Target]' --output text
aws ssm terminate-session --session-id <session-id>
```

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `SessionManagerPlugin is not found` | Install the Session Manager plugin (prerequisite 2) and open a new terminal. |
| `TargetNotConnected` | The instance isn't running, or its SSM agent isn't online yet. Check step 2; after a fresh deploy wait a few minutes. |
| `AccessDeniedException` on `StartSession` | Your identity lacks `ssm:StartSession` for the instance or the port-forwarding document. |
| Browser shows the nginx welcome page | You forwarded port 80. Forward 8080 instead. |
| `Address already in use` | The local port is taken. Use a different `localPortNumber`. |
| Login page keeps rejecting the password | Use the stack's `Password` output (step 3). It is not the AWS account ID. |
| Session drops after a while idle | Session Manager's idle timeout (20 minutes by default, set in Session Manager preferences). Start the session again; code-server reconnects. |
| `describe-instances` returns `None` | Wrong region, or the instance isn't tagged `eksworkshop-kiroide` (check `INSTANCE_NAME` used with `deploy-stack.sh`). |

## Security notes

- The Session Manager plugin listens on your laptop's loopback interface only, so the forwarded port isn't reachable by other machines on your network.
- Port forwarding needs no inbound security group rules and puts nothing on the internet, unlike `cre-origin.sh`.
- Access is controlled by IAM: anyone who can call `ssm:StartSession` on the instance can open the tunnel, and anyone who can read the stack outputs can read the password. The instance role has `AdministratorAccess`, so treat both permissions as admin-equivalent.
- Sessions are recorded in CloudTrail (`StartSession` events).
