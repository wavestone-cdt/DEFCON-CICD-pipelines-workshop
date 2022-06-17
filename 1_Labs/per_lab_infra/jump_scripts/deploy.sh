#! /bin/bash

sudo apt-get update
sudo apt-get install -y \
  curl \
  ca-certificates \
  nginx \
  awscli \
  python3 \
  python3-pip \
  supervisor \
  x11vnc xvfb \
  novnc \
  jq \
  xrdp \
  xclip \
  kali-desktop-xfce \
  firefox-esr

python3 -m pip install -U pip

# specfic tools will be added here
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
rm -f kubectl

curl -LO https://github.com/aquasecurity/kubectl-who-can/releases/download/v0.4.0/kubectl-who-can_linux_x86_64.tar.gz
mkdir kubectl-who-can
tar xzf kubectl-who-can_linux_x86_64.tar.gz -C kubectl-who-can
sudo install -o root -g root -m 0755 kubectl-who-can/kubectl-who-can /usr/local/bin/kubectl-who-can
rm -rf kubectl-who-can_linux_x86_64.tar.gz kubectl-who-can

## TODO Install docker for gitleaks and trufflehog
sudo apt-get install -y libssl-dev libffi-dev
python3 -m pip install trufflehog pycrypto


sudo apt-get autoremove -y
sudo apt-get autoclean -y

sudo aws configure set region ${region}
aws s3 cp s3://${bucket}/supervisord.conf /etc/supervisor/conf.d/
aws s3 cp s3://${bucket}/nginx.conf /etc/nginx/
aws s3 cp s3://${bucket}/authfile /etc/nginx/
mkdir /writeup
aws s3 cp s3://${bucket}/jump_writeup/ /writeup/ --recursive
chown -R kali: /writeup

## Replace specific variable inside the writeup
### use # as separator to prevent conflics with / in secrets and CIDR
find /writeup -type f -exec sed -i "s#{PLACEHOLDER_LAB_ID}#${lab_id}#g" '{}' \;
find /writeup -type f -exec sed -i "s#{PLACEHOLDER_LAB_NAME}#${lab_name}#g" '{}' \;
find /writeup -type f -exec sed -i "s#{PLACEHOLDER_APP_AWS_ACCESS_KEY_ID}#${app_id}#g" '{}' \;
find /writeup -type f -exec sed -i "s#{PLACEHOLDER_APP_AWS_SECRET_ACCESS_KEY}#${app_secret}#g" '{}' \;
find /writeup -type f -exec sed -i "s#{PLACEHOLDER_REGION}#${region}#g" '{}' \;
find /writeup -type f -exec sed -i "s#{PLACEHOLDER_K8S_CLUSTER}#${k8s_cluster}#g" '{}' \;
find /writeup -type f -exec sed -i "s#{PLACEHOLDER_LAB_CIDR}#${lab_cidr}#g" '{}' \;
find /writeup -type f -exec sed -i "s#{PLACEHOLDER_K8S_JENKINS_ACCESS_KEY_ID}#${k8s_jenkins_id}#g" '{}' \;
find /writeup -type f -exec sed -i "s#{PLACEHOLDER_K8S_JENKINS_ACCESS_KEY_SECRET}#${k8s_jenkins_secret}#g" '{}' \;
find /writeup -type f -exec sed -i "s#{PLACEHOLDER_K8S_MONITORING_ACCESS_KEY_ID}#${k8s_monitoring_id}#g" '{}' \;
find /writeup -type f -exec sed -i "s#{PLACEHOLDER_K8S_MONITORING_ACCESS_KEY_SECRET}#${k8s_monitoring_secret}#g" '{}' \;
find /writeup -type f -exec sed -i "s#{PLACEHOLDER_KALI_REPO_URL}#${kali_repo_url}#g" '{}' \;

# pre-generate the aws credentials and options
mkdir -p ~kali/.aws
cat > ~kali/.aws/credentials <<EOF
[jenkins]
aws_access_key_id=${k8s_jenkins_id}
aws_secret_access_key=${k8s_jenkins_secret}

[monitoring]
aws_access_key_id=${k8s_monitoring_id}
aws_secret_access_key=${k8s_monitoring_secret}

[aws]
aws_access_key_id=${app_id}
aws_secret_access_key=${app_secret}
EOF
cat > ~kali/.aws/config <<EOF
[profile jenkins]
region=${region}

[profile monitoring]
region=${region}

[profile aws]
region=${region}
EOF
chown -R kali: ~kali/.aws

private_ip=`/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1`
find /writeup -type f -exec sed -i "s#{PLACEHOLDER_PRIVATE_IP}#$${private_ip}#g" '{}' \;

sudo service nginx start
sed -i 's#port=3389#port=tcp://:3389#g' /etc/xrdp/xrdp.ini
sudo service xrdp start

# Change kali user password
echo ${password} > /writeup/password
echo kali:${password} | sudo chpasswd
htpasswd -b -c /etc/nginx/authfile kali ${password}

# Enable SSH password auth
sudo sed -i 's/^\s*PasswordAuthentication .*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl reload sshd.service

#Download jenkins scripts
wget https://raw.githubusercontent.com/gquere/pwn_jenkins/master/offline_decryption/jenkins_offline_decrypt.py
wget https://raw.githubusercontent.com/gquere/pwn_jenkins/master/dump_builds/jenkins_dump_builds.py

apt-get install python3.9-dev -y
python3.9 -m pip install pycrypto

## Do not add code after this line
sudo supervisord -n
