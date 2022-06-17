# Let's dump all build logs !
python3.9 /writeup/3_Credentials-Hygiene-v2/jenkins_dump_builds.py -u read_user -p SecureP4ssw0rd! -o dump_logs https://{PLACEHOLDER_LAB_NAME}-jenkins.devsecoops.academy

 grep "password" -R dump_logs

# Alternatively, you could reuse trufflehog or gitleaks
