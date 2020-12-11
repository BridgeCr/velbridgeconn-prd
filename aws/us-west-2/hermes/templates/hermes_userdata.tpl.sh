#!/usr/bin/env bash
export AWS_DEFAULT_REGION="${region}"

# Install monit + AWS monitoring script prerequirements
amazon-linux-extras install epel -y
yum install monit perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA.x86_64 -y

# Configure monit for Mirth
cat > /etc/monitrc <<EOF
set daemon  15
set log syslog
set httpd port 2812 and
    use address localhost
    allow localhost
    allow admin:vGRn6kaoys1i3ehzpYWt

include /etc/monit.d/*

### Start Mirth ###
check process mcservice with pidfile /opt/mirthconnect/mcservice.pid
start program = "/bin/systemctl start mirth"
stop program = "/bin/systemctl stop mirth"
EOF

chmod 700 /etc/monitrc

# create systemd service
cat > /etc/systemd/system/mirth.service <<EOF
[Unit]
Description=Mirth Service
After=network.target

[Service]
User=root
Group=root
Type=forking
ExecStart=/opt/mirthconnect/mcservice start
ExecStop=/opt/mirthconnect/mcservice stop
LimitNOFILE=65535
PIDFile=/opt/mirthconnect/mcservice.pid

[Install]
WantedBy=multi-user.target
EOF

# Install AWS monitoring scripts
cd /opt
curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O
unzip CloudWatchMonitoringScripts-1.2.2.zip
rm -f CloudWatchMonitoringScripts-1.2.2.zip
echo "# Posts metrics to Cloudwatch" > /var/spool/cron/ec2-user
echo "*/1 * * * * /opt/aws-scripts-mon/mon-put-instance-data.pl --mem-used --mem-avail --disk-path=/ --disk-space-used --disk-space-avail --from-cron" >> /var/spool/cron/ec2-user

# Clean up service file that is no longer required
rm /etc/rc.d/mcservice

## Install Mirth from remote RPM
yum -y install java-1.8.0-openjdk cifs-utils python3-pip amazon-ssm-agent
pip3 install awscli

rpm -ivh http://downloads.mirthcorp.com/connect/${version}/mirthconnect-${version}-linux.rpm

# Edit /opt/mirthconnect/mcservice start up script to create/remove .pid file when process starts/stops/restarts
# Create pid for case = start
sed -i '479 a echo $! > /opt/mirthconnect/mcservice.pid' /opt/mirthconnect/mcservice

# Create pid for case = start-launchd
sed -i '489 a echo $! > /opt/mirthconnect/mcservice.pid' /opt/mirthconnect/mcservice

# Create pid for case = restart|force-reload
sed -i '511 a echo $! > /opt/mirthconnect/mcservice.pid' /opt/mirthconnect/mcservice

# Create empty pid for Mirth daemon
touch /opt/mirthconnect/mcservice.pid

cat > /opt/mirthconnect/conf/mirth.properties <<EOF
dir.appdata = appdata
dir.tempdata = \$${dir.appdata}/temp
http.port = 8080
https.port = 8443
keystore.path = \$${dir.appdata}/keystore.jks
keystore.storepass = 81uWxplDtB
keystore.keypass = 81uWxplDtB
keystore.type = JCEKSadministrator.maxheapsize = 512m
database = postgres
database.enable-read-write-split = true
database.url = jdbc:postgresql://${db_endpoint}:5432/${db_name}
database.username = ${db_username}
database.password = ${db_password}
database-readonly.url = jdbc:postgresql://${db_ro_endpoint}:5432/${db_name}
EOF

jvmHeap="$(echo "$(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 * 0.85 / 1" | bc)m"

cat > /opt/mirthconnect/mcservice.vmoptions <<EOF
-server
-Xmx$jvmHeap
-Djava.awt.headless=true
-Dapple.awt.UIElement=true
EOF

cat > /opt/mirthconnect/mcserver.vmoptions <<EOF
-server
-Xmx$jvmHeap
-Djava.awt.headless=true
-Dapple.awt.UIElement=true
EOF

PARAM_CLIENTS=$(aws ssm describe-parameters --filters "Key=Name,Values=/mirth/smb/" --query "Parameters[*].Name" --output text)
while read uc; do
  P_USER=$(aws ssm get-parameter --with-decryption --name "/mirth/smb/$${uc}/user" --query "Parameter.Value" --output text)
  P_PASS=$(aws ssm get-parameter --with-decryption --name "/mirth/smb/$${uc}/pass" --query "Parameter.Value" --output text)
  P_PATH=$(aws ssm get-parameter --with-decryption --name "/mirth/smb/$${uc}/path" --query "Parameter.Value" --output text)
  cat > /root/.$${uc}creds <<EOF
username=$${P_USER}
password=$${P_PASS}
EOF
  chmod 600 /root/.$${uc}creds

  mkdir -p /mnt/$${uc}
  echo "$${P_PATH}  /mnt/$${uc} cifs  credentials=/root/.$${uc}creds,uid=1000,gid=1000,_netdev,defaults 0 0" >> /etc/fstab
done < <(echo "$${PARAM_CLIENTS}" | awk 'BEGIN {RS="\t"; FS="/"}{ print $4 }' | uniq)

mount -a

# Install filebeat
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch

cat > /etc/yum.repos.d/elastic.repo <<EOF
[elastic-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

yum install filebeat -y

cat > /etc/filebeat/filebeat.yml <<EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /opt/mirthconnect/logs/mirth.log
    - /var/log/messages
    - /var/log/monit.log
  exclude_lines: ['^DBG']
  fields:
   mirthapp: ${env}

# cloud.id: :dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyQzYmRhNDFmMWQxZTk0YmQ0OTE4YWFmZGRjNjg2NzQ1ZSQ0YmFhMDEyNzU1ODA0NDNlOThmZTMxNDU4NTMwYmY1Yw==
# cloud.auth: elastic:qGhGnZXQkA6cZTfluOXBGBWO

# output.elasticsearch:
#   output.elasticsearch.index: "prod-%%{[agent.version]}-%%{+yyyy.MM}"
#   hosts: "https://3bda41f1d1e94bd4918aafddc686745e.us-east-1.aws.found.io:elasticsearch:9243:9200"
#   username: "elastic"
#   password: "qGhGnZXQkA6cZTfluOXBGBWO"

setup.ilm:
  enabled: auto
  rollover_alias: "filebeat-prod"
  pattern: "{now/d}-000001"
  check_exists: "true"
  policy_name: "filebeat-7.0.0-prod"

processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
EOF

systemctl enable filebeat
systemctl start filebeat

cat > /etc/rc.local <<EOF
# ensure monit start up on boot
monit
monit start all

exit 0
EOF

# Create ansible user
useradd -m -s /bin/bash ansible
mkdir /home/ansible/.ssh
touch /home/ansible/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhW47qaGUblpjp+ZKED2UbKOrPqTzEcefZ5ed1kvrpJtsbxq7bxR4vjjHWsZUcKvM+RuPw+hQYhdceAQ8dDPbLp9f1QtN0r2vtnclHTdU3PeA0/m7pRCm//eo0LHOS9PnH4OnQbAtDRhTnBEt3FEa4Hy/aKsj6J/8RnOx03RSNKh44ZL2P53YqU81qzI1UJ5GLBckNh15oKKip0Q47oz40K/b0avMgqnTX6T3ctar5+LHZ44A6vfE71yjW6Fu0NVL0NOnpuCH9xkw1M/B5sCGP/iGTMvDZvUEnAyzXjgfi7vNnYb2nJw+qfOI4CpoRrbM6bASyXldhUJlIRNEmS6bH" > /home/ansible/.ssh/authorized_keys
chown -R ansible:ansible /home/ansible
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys
echo "ansible ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "Defaults:ansible !requiretty" >> /etc/sudoers

# Ensure rc.local can execute on each boot
chmod +x /etc/rc.d/rc.local

/usr/local/bin/aws s3 sync --sse aws:kms s3://hermes-enterprise/library-files /opt/mirthconnect/custom-lib
/usr/local/bin/aws s3 sync --sse aws:kms s3://hermes-enterprise/keys /opt/mirthconnect/conf

# DSO-1273 CONT
systemctl enable mirth
systemctl start mirth
monit
monit start all
