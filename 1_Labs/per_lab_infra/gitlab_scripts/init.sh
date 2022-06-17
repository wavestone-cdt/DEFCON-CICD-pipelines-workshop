#! /bin/bash

sleep 300
will start updating the url to jenkins.lab : ${lab_id} with api key : ${gitlab_api_key}'
curl -X PUT -d url=https://${lab_id}-jenkins.devsecoops.academy/project/Our%2520awesome%2520webapp --insecure https://localhost/api/v4/projects/22/hooks/4?private_token=${gitlab_api_key}

curl -X POST -d "state=success&target_url=https://${lab_id}-jenkins.[YOUR_DOMAIN_NAME]" --insecure https://localhost/api/v4/projects/22/statuses/eac7188a309fa39a9ec2ee837b003c8b69fa0b47?private_token=${gitlab_api_key}
sed -i "s#gitlab.[YOUR_DOMAIN_NAME]#${lab_id}-gitlab.[YOUR_DOMAIN_NAME]#g" /etc/gitlab/gitlab.rb
echo "letsencrypt['enable'] = false" >> /etc/gitlab/gitlab.rb
echo "nginx['redirect_http_to_https'] = true" >> /etc/gitlab/gitlab.rb

# TODO : Adapt to use user provided certificate instead of AMI stored one 
mv /etc/gitlab/ssl/[YOUR_DOMAIN_NAME].crt /etc/gitlab/ssl/${lab_id}-gitlab.YOUR_DOMAIN_NAME].crt
mv /etc/gitlab/ssl/[YOUR_DOMAIN_NAME].key /etc/gitlab/ssl/${lab_id}-gitlab.[YOUR_DOMAIN_NAME].key
gitlab-ctl reconfigure
gitlab-ctl hup nginx registry

# We need to strip older authorized_keys and i'm too lazy to create a new AMI
tail -n 1 /home/ubuntu/.ssh/authorized_keys > /home/ubuntu/.ssh/tmp
mv /home/ubuntu/.ssh/tmp /home/ubuntu/.ssh/authorized_keys
chown ubuntu: /home/ubuntu/.ssh/authorized_keys
