# Table of contents

* [About the project](#about-the-project)
* [Installation](#installation)
* [Usage](#usage)
* [Authors](#authors)
* [License](#license)

# About the project

This Bash script automates the setup of a new Apache2 VirtualHost, complete with:

* Custom domain configuration (with optional www. subdomain)
* Directory structure creation
* Let's Encrypt SSL certificate setup

### Features

✍ **User inputs**
* Domain name (e.g. example.com)
* E-Mail address (used for Let's Encrypt registration)
* New system username
* Optional www. subdomain support

📂 **Directory structure:**
* Creates following directorys:
```
/var/www/<domain>/
├── httpdocs   # Web root
├── logs       # Apache logs
└── files      # Optional file storage
```

🔑 **User & permissions:**
* Adds new user (if not existing) with:
* Home directory at /var/www/<domain>
* /usr/sbin/nologin shell (no terminal access)
* Sets ownership and permissions for web and SFTP usage
* User belongs to www-data group

> [!TIP]
> For later FTP access please read the note.

**FTP Access tip**

For FTP access to work, you must change the user's shell from /usr/sbin/nologin to /bin/false. This is required because the script currently sets the user's shell to /usr/sbin/nologin to prevent terminal access. To enable FTP, you can run the following command:

```
sudo chsh -s /bin/false username
```

Replace username with the actual username of the user. This will allow FTP access while still preventing terminal login.

> [!TIP]
> Additionally, make sure your FTP server (e.g. ProFTPD or vsftpd) is configured to allow logins only for users with /bin/false as their shell.
> This ensures that only explicitly designated FTP users are allowed to connect, improving security.

🛠️ **Apache configuration:**
* Creates basic HTTP VirtualHost with automatic redirect to HTTPS
* Enables rewrite and ssl modules
* Requests a Let's Encrypt certificate using Certbot
* On success, appends a full HTTPS VirtualHost configuration
* Removes default -le-ssl.conf created by Certbot to avoid conflicts

# Installation

Clone this repo:
```
git clone https://github.com/maralexofficial/apache2-vhost-generator.git
```

Change directory to
```
cd apache2-vhost-generator
```

To run this script we should add permission

```
chmod +x apache2-vhost-generator
```

# Usage

```
./apache2-vhost-generator
```

# Authors

* [maralexofficial](https://github.com/maralexofficial)

# License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
