yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Create ansible user
useradd -m -s /bin/bash ansible
mkdir /home/ansible/.ssh
touch /home/ansible/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDChbQoUqdos+IB3r2HkUNDW2iVS0Lw9EBCtaknWJlGwYxEiQtEWxG789fW4wSM+s830U2KsDl57taK5mRIpk92kQObarRRkH2MgNx1ROJ0r6EgoJk1wkG5jw49K/XGkQPxbcgQCocH1V+HET33/amdcVasAt8wA2acoPltmvo8RhPrx4MRRHmJCRxOcY6kIQU/vlyZcGh6tu6BdKg+w8BLjTNLF0fGusDi1TqunxYEVBVdmhMzbGlI0AO9dkwMkdMsD3b5bzM4dcqZweT646HBcBuG5EzBDUj3ouHT6QoSLU4XSZPw4TRE4pu1zEwmMILw5wCzIiEp9hp9G1TZ04Tl" > /home/ansible/.ssh/authorized_keys

chown -R ansible:ansible /home/ansible
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys

echo "ansible ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "Defaults:ansible !requiretty" >> /etc/sudoers

# Kick off playbook
#curl -f -H 'Content-Type: application/json' -XPOST -d '{"host_config_key": "e8e2f6ff-bda6-4fbb-a35b-4deb6aadb067"}' https://awx.bcrdev.us:443/api/v2/job_templates/208/callback/
