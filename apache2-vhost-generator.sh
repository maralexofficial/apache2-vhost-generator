#!/bin/bash

read -p "Domain (e.g. example.com): " DOMAIN

if [[ -z "$DOMAIN" ]]; then
    echo "----------------------"
    echo "❌ Domain is required."
    echo "----------------------"
    exit 1
fi

read -p "E-Mail for Let's Encrypt notifications: " EMAIL

if [[ -z "$EMAIL" ]]; then
    echo "---------------------"
    echo "❌ Email is required."
    echo "---------------------"
    exit 1
fi

read -p "Username for the new user (e.g. exampleuser): " USERNAME

if [[ -z "$USERNAME" ]]; then
    echo "-------------------------"
    echo "❌ Username is required."
    echo "-------------------------"
    exit 1
fi

read -p "Setup www.${DOMAIN} as alias? (y/n): " ADD_WWW

DOCROOT="/var/www/${DOMAIN}"
HTTPDOCS_PATH="${DOCROOT}/httpdocs"
LOG_PATH="${DOCROOT}/logs"
VHOST_PATH="/etc/apache2/sites-available/${DOMAIN}.conf"
AUTHORIZED_KEY_PATH="${DOCROOT}/.ssh/authorized_keys"

if [[ "$ADD_WWW" == "y" || "$ADD_WWW" == "Y" ]]; then
    WWW_ALIAS="ServerAlias www.${DOMAIN}"
    CERT_DOMAINS="-d ${DOMAIN} -d www.${DOMAIN}"
else
    WWW_ALIAS=""
    CERT_DOMAINS="-d ${DOMAIN}"
fi

for dir in httpdocs logs files; do
    sudo mkdir -p "${DOCROOT}/${dir}"
done

if ! id "$USERNAME" &>/dev/null; then
    echo "🔧 Creating user: $USERNAME"
    sudo useradd -d "$DOCROOT" -s /usr/sbin/nologin -m "$USERNAME"
    sudo passwd "$USERNAME"
    echo "👤 User '$USERNAME' created with home: $DOCROOT"
else
    echo "ℹ️ User '$USERNAME' already exists."
fi

sudo chown root:root "$DOCROOT"
sudo chmod 755 "$DOCROOT"
sudo chown -R $USERNAME:www-data "${DOCROOT}/httpdocs" "${DOCROOT}/logs" "${DOCROOT}/files"
sudo find "${DOCROOT}" -type d -exec chmod 2775 {} \;
sudo find "${DOCROOT}" -type f -exec chmod 664 {} \;

echo "<h1>${DOMAIN} is working with HTTPS!</h1>" | sudo tee "${HTTPDOCS_PATH}/index.html" > /dev/null

cat <<EOF | sudo tee "$VHOST_PATH" > /dev/null
<VirtualHost *:80>
    ServerName ${DOMAIN}
    ${WWW_ALIAS}

    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^/?(.*) https://%{SERVER_NAME}/\$1 [R=301,L]
</VirtualHost>
EOF

sudo a2enmod rewrite ssl
sudo a2ensite "${DOMAIN}.conf"
sudo systemctl reload apache2

echo "🔐 Requesting SSL certificate via Let's Encrypt..."

SSL_SUCCESS=false

if sudo certbot --apache $CERT_DOMAINS --non-interactive --agree-tos -m "$EMAIL"; then
    echo "✅ SSL certificate obtained successfully."
    SSL_SUCCESS=true

    cat <<EOF | sudo tee -a "$VHOST_PATH" > /dev/null

<VirtualHost *:443>
    ServerName ${DOMAIN}
    ${WWW_ALIAS}
    DocumentRoot ${HTTPDOCS_PATH}

    <Directory ${HTTPDOCS_PATH}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${LOG_PATH}/error.log
    CustomLog ${LOG_PATH}/access.log combined

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/${DOMAIN}/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/${DOMAIN}/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
EOF

    sudo systemctl reload apache2
else
    echo "❌ SSL setup failed. HTTP only for now."
fi

SSL_CONF_FILE="/etc/apache2/sites-enabled/${DOMAIN}-le-ssl.conf"
if [ -f "$SSL_CONF_FILE" ]; then
    echo "🗑️ Removing default SSL conf: $SSL_CONF_FILE"
    sudo rm "$SSL_CONF_FILE"
fi

# Restart Apache for all changes
echo "🔄 Restarting Apache2..."
sudo systemctl restart apache2

# Output summary
echo ""
echo "✅ Setup complete:"

if $SSL_SUCCESS; then
    echo "🌐 Domain: https://${DOMAIN}"
else
    echo "🌐 Domain: http://${DOMAIN}"
fi

echo "📁 Document Root: ${DOCROOT}"
echo "👤 User: ${USERNAME} (SFTP-only)"

# Final root wisdom 😎
echo ""
echo "🧙‍♂️ Root wisdom of the day: 'With great power comes great `chmod 700`.'"
