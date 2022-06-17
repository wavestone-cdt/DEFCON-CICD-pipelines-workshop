# Labs

The labs is composed of:
- Common architecture which are mutualized resources (e.g. VPC)
- Per lab architecture which are all resources associated to a lab

A wrapper around terraform was created to correctly managed them. The wrapper
accept any command supported by terraform. For more details see
`./terraform.sh -help`.

## Dependencies

The following programs should be available and configured:
- `sed`
- `awscli`
- `docker`
- `kubectl`

## How to deploy a lab

The lab management relies on several bash scripts.

### Initialization

First thing is to initialize the terraform environment. For that purpose
use:
```
$ ./initialize
Usage: initialize <max_lab_count>
```

It must be provided the maximum number of labs you may deploy. It is necessary
to limit generation of resources. You will still be able to deploy 1 lab if
you specify a max value of 100.

What it does is:
- it pre-generate several passwords to access the lab jump servers
- it update config to reflect the new max lab count
- it generate a new SSH key for presenters
- it initialize terraform workspaces


### Deployment

To deploy a lab, use:
```
$ ./deploy
Usage: deploy <lab_count> [<terraform args>...]
```

It must be provided the number of labs to be deployed. It automatically resize
the number of labs and destroy resources which do not need it anymore.

Any extra argument is provided to all `terraform.sh` commands.

In addition, the environment variable `PARALLEL` may be defined to set the
number of labs to be created/deleted in parallel (default to 10).

It:
- deploys the given number of labs,
- push used docker images to ECR (to prevent reaching DockerHub limits)
- delete Kubernetes resources which should not be kept

## Destroy

To destroy all labs and common infrastructure use:
```
$ ./destroy
```
**Careful**: no validation will be asked before removing the lab
