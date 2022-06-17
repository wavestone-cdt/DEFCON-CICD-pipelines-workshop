# Authentication
To authenticate on the cluster with kubectl:
1. configure AWS credentials in `~/.aws/credentials` (*note*: credentials was
already added to the file)
```
[jenkins]
aws_access_key_id={PLACEHOLDER_K8S_JENKINS_ACCESS_KEY_ID}
aws_secret_access_key={PLACEHOLDER_K8S_JENKINS_ACCESS_KEY_SECRET}
```

2. configure kubectl with AWS credentials:
```shell
aws eks update-kubeconfig --profile=jenkins --name={PLACEHOLDER_K8S_CLUSTER}
```

# Exploring the cluster

## Understanding namespaces

```shell
kubectl get namespaces
```

Several namespaces are default ones: kube-system, kube-public, default…

## Understanding what the current user can do

```shell
kubectl auth can-i --list
kubectl auth can-i --list -n business-app
kubectl auth can-i --list -n aws-app
kubectl auth can-i --list -n monitoring-app
```

You can try the latest command with several discovered namespaces like
business-app, monitoring-app or aws-app

## Searching RBAC

Using Aquasecurity's kubectl-who-can may help speeding up access resolution:
```shell
# who can read secrets
kubectl-who-can get secret -n business-app
kubectl-who-can get secret -n aws-app
kubectl-who-can get secret -n monitoring-app

# who can create pods
kubectl-who-can create pod -n business-app
kubectl-who-can create pod -n aws-app
kubectl-who-can create pod -n monitoring-app
```

## Studying PodSecurityPolicies

```shell
kubectl get podsecuritypolicies
kubectl-who-can use podsecuritypolicy/eks.privileged
```

