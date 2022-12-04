#!/bin/bash

echo "This script aims to setup your nginx! Please setup A record pointing to your ip address before proceeding"

echo "Please enter website domain name then press enter" 
read websiteName

echo "Please enter container_id or container_name then press enter" 
read container

containerIP=$(sudo docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container)

rm /etc/nginx/sites-available/$websiteName
rm /etc/nginx/sites-enabled/$websiteName

sudo touch /etc/nginx/sites-available/$websiteName

echo "
server {
	listen 80;
	server_name ${websiteName};
	location / {
		proxy_pass http://${containerIP};
	        proxy_set_header Host \$host;
	        proxy_set_header X-Real-IP \$remote_addr;
	        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
	        proxy_set_header X-Forwarded-Proto \$scheme;
			access_log /var/log/nginx/access.$websiteName.log ;
            error_log /var/log/nginx/error.$websiteName.log;

	}
}
" > /etc/nginx/sites-available/${websiteName}

sudo nginx -t
sudo ln -s /etc/nginx/sites-available/${websiteName} /etc/nginx/sites-enabled/
sudo systemctl restart nginx

echo "Do you want to install certbot... yes|no ?"
read certbot

if [ "$certbot" = "yes" ]; then
    echo "Certbot is under setup" as true
    sudo certbot --nginx -d $websiteName
else
    echo "Abort certbot setup!" as false
fi
