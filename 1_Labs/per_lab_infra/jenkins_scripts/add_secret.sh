#! /bin/bash
exec 19>/var/log/cloud-init-output_trace.txt
BASH_XTRACEFD=19
set -x

sleep 120

# k8s user
echo "K8s secret uploading"
cat > credential.xml <<EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>eks_secret</id>
  <description>This is the AWS secret to deploy on the cluster ${k8s_cluster}</description>
  <username>${k8s_user}</username>
  <password>
    ${k8s_secret}
  </password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF

curl -X POST \
    -u jenkins:${jenkins_api_key} \
    -H 'content-type:application/xml' \
    -d @credential.xml \
    --insecure \
    "https://localhost/credentials/store/system/domain/_/createCredentials"

# Let's update job configuration``
JOBNAME="Our%20awesome%20webapp Simple%20Java%20Maven%20App MLTK jdial JavaDoc_builder"
for job in $JOBNAME; do
    curl -X GET -u jenkins:${jenkins_api_key}  -H 'content-type:application/xml' --insecure -o awesomeapp.xml "https://localhost/job/$${job}/config.xml"
    sed -i "s#gitlab.devsecoops.academy#${lab_id}-gitlab.devsecoops.academy#g" awesomeapp.xml
    sed -i "s#http://#https://#g" awesomeapp.xml
    sed -i "s#54.177.227.218#${lab_id}-gitlab.devsecoops.academy#g" awesomeapp.xml
    curl -X POST -u jenkins:${jenkins_api_key}  -H 'content-type:application/xml' --insecure --data-binary @awesomeapp.xml "https://localhost/job/$${job}/config.xml"
    rm awesomeapp.xml
done

rm /bitnami/jenkins/home/.ssh/known_hosts

rm /var/log/cloud-init*
