#!/bin/bash
sudo su
yum update -y
yum install docker -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
mv /usr/local/bin/docker-compose /bin/docker-compose
yum install nfs-utils -y
mkdir /mnt/efs/
chmod +rwx /mnt/efs/
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ID_DO_EFS.efs.us-east-1.amazonaws.com:/ efs
echo "ID_DO_EFS.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs defaults 0 0" >> /etc/fstab
echo "version: '3.3'
services:
  wordpress:
    image: wordpress:latest
    volumes:
      - /mnt/efs/wordpress:/var/www/html
    ports:
      - 80:80
    restart: always
    environment:
      WORDPRESS_DB_HOST: Endpoint do rds aqui
      WORDPRESS_DB_USER: master user do rds
      WORDPRESS_DB_PASSWORD: master password do rds
      WORDPRESS_DB_NAME: initial name do rds
      WORDPRESS_TABLE_CONFIG: wp_" | sudo tee /mnt/efs/docker-compose.yml
cd /mnt/efs && sudo docker-compose up -d
