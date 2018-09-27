echo "Please add the following to your nginx config:"
cat wellknown.txt

read -p "Have you added it? (y/n)" -n 1 -r
echo "\n"
if [[ $REPLY =~ ^[Nn]$ ]]
then
    echo "Well, then go add it! :("
    exit
fi

echo 'Where is the webroot of your project? (example /var/www/myapp)'
read webroot

echo 'What is the domain name? (example myapp.com)'
read domain

echo 'deb http://ftp.debian.org/debian jessie-backports main' | tee /etc/apt/sources.list.d/backports.list
apt-get update

echo 'Installing certbot'
apt-get install certbot -t jessie-backports

echo 'Checking for errors in NGINX...'
nginx -t
systemctl restart nginx
echo 'If you saw any NGINX errors, please fix them and restart this script'

echo 'Requesting certificates, using (~ / .well-known)'
certbot certonly -a webroot --webroot-path=$webroot -d $domain
ls -l /etc/letsencrypt/live/$domain

read -p "Do you want to generate a Diffie-Hellman Group? (y/n)" -n 1 -r
echo "\n"
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo 'Creating Diffie-Hellman Group'
    openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048; wait;
    echo 'Done!'
fi

echo "Creeating ssl-$domain.conf"
echo "ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;" >> /etc/nginx/snippets/ssl-$domain.conf
echo "ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;" >> /etc/nginx/snippets/ssl-$domain.conf

echo "Creating ssl-params.conf"
cp ./ssl-params.conf /etc/nginx/snippets/.

echo "Now edit your nginx config to look something like this:"
cat https.txt

echo "To setup auto renewal, run:"
echo "crontab -e"
echo "And add the following:"
echo '30 2 * * * /usr/bin/certbot renew --noninteractive --renew-hook "/bin/systemctl reload nginx" >> /var/log/le-renew.log'

echo "====* Congratulations *===="
echo "... "
