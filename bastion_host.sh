#!/bin/bash
# NAT Instance configuration
sudo yum install iptables-services -y
sudo systemctl enable iptables
sudo systemctl start iptables
sudo sysctl -w net.ipv4.ip_forward=1
sudo /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo /sbin/iptables -F FORWARD

# Setup Reverse Proxy
# Install nginx on AL2:
sudo amazon-linux-extras install nginx1 -y
sudo systemctl start nginx.service
# Configure reverse-proxy. The Private IP of k3s Server instance must be declared
sudo touch /etc/nginx/conf.d/proxy.conf
sudo echo 'server {
        listen 80;
        server_name localhost 127.0.0.1;
        location / {
          proxy_pass         http://10.0.3.58:32000;
          proxy_redirect     http://10.0.3.58:32000/ /;
          proxy_set_header   Host $host;
          proxy_set_header   X-Real-IP $remote_addr;
          proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header   X-Forwarded-Host $server_name;
        }
    }' >> /etc/nginx/conf.d/proxy.conf
sudo service nginx restart
# Accept inbound connections on port 80
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT