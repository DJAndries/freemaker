# freemaker

Ansible playbooks that replace cloud software. Self-hosted Email, Nextcloud, and simple security via port knocking.

Designed for fresh Debian installs.

## Features

### Unattended install

- Debian preseeding scripts available for unattended Debian installs
  - Creates preseeded ISO
- Preseeded ISO configuration
  - Temporary user & password
  - Encrypted LVM

### Security

- Configures a passphrase for an encrypted LVM
- Creates admin user, adds sudo
- SSHD, adds an ssh key, disables password authentication, SSH port customizable
- UFW firewall setup, whitelists home IP address by default
  - Open to Internet: Port 25 for SMTP, port of your choosing for SSH
  - Behind firewall: Port 587, 993 (Dovecot/Postfix), Port 8443 (Nginx/Nextcloud)
- Sets up a port knocking daemon, which will whitelist IP addresses upon a correct knock
  - Feel free to use my Port Knocker app on Android, if you need to whitelist yourself on the go
  - Whitelist only lasts one hour
  - One time port sequence generation script included: `gen_port_seqs`
- Sets up fail2ban. Automatically bans IPs that perform five failed authentication attempts over IMAP and SMTP
- Sets up certbot/Letsencrypt SSL/TLS certificate. Configured to reload nginx and postfix.

### Software

- Self-hosted email solution using Dovecot/Postfix (uses a slightly modified version of Luke Smith's [emailwiz](https://github.com/djandries/emailwiz) script)
  - IMAP/SMTP setup
  - PAM authentication
- Mailgun SMTP relay, to ensure email delivery for recipients
- Docker
- Sets up Nextcloud in Docker, behind nginx.
- Backup/restore scripts
  - `mail_backup`, `mail_restore` scripts: Backs up all user email
  - `nextcloud_backup`, `nextcloud_restore`: Backs up all files and data in Nextcloud
- Basic utilities: curl, vim, htop, git, pip

## Dependencies

- Ansible
- Docker (optional, used for creating a preseeded Debian ISO, if unattended OS installs are desired)

## Usage

0. If an unattended Debian install is desired, modification of a few attributes in `preseeder/preseed.cfg` can be done.

Some recommended modifications:
- `language`
- `country`
- `locale`

1. Install Debian on your VPS instance

**If using [Vultr](https://www.vultr.com/?ref=8661862-6G)** (we both get credit if you use this link to sign up), the `deploy_vultr.sh` script can be used to:
- Preseed a Debian ISO for an unattended install
- Upload the custom ISO to Vultr
- Deploy a Vultr instance with 1 GB RAM in Toronto (5$ / month)

**If not using Vulr**:
- If performing an unattended install, run `preseeder/docker_preseed.sh` to create a preseeded ISO.
- Or install Debian manually


2. If using preseeded ISO, select 'Install' from the boot menu. When the install completes, the menu will reappear. Unmount the ISO at this point.
3. Once rebooted, enter your LVM encryption password to boot Debian. (If using the preseeded ISO, the password is 'Testtest1!').
4. Add an A record for a subdomain of your choosing, pointing to the VPS instance.
5. Connect to the instance via SSH so the instance is added to your `known_hosts`. (User: tempuser, Password: Testtest1! if using the preseeded ISO).
6. Copy `inventory/hosts.yml.example` to `inventory/hosts.yml`. Edit accordingly.
7. Call `ansible-vault create inventory/vault.yml` to create an encrypted vault. This will be used to store any credentials. Copy the contents of `vault.yml.example` into the edtior. Edit accordingly.
8. Run `bootstrap.sh`. This will configure SSHD and a new admin user.
9. Run `main.sh`. This will provision everything else.
10. At the end, some DNS entries related to the mail server will be shown. Input these into your registrar/DNS server.

## Notes

### Port knocking

The port knocking daemon is configured with a "master" sequence, and some one-time sequences. The one-time sequences are stored in `/usr/local/etc/port_seqs`. The one-time sequences must be used sequentially. Once used, they cannot be used again. Running `gen_port_seqs` as root will generate 30 new port sequences. Users are recommended to use the one-time sequences (especially in public places), to prevent a sniffing attack.

### Mailgun

In this playbook, Mailgun is used for outgoing transactional emails. Mail server IP reputation is hard to gain with popular mail providers. Without reputation (and a mail relay such as Mailgun), emails will go to the junk folder when sending to Gmail, Hotmail, etc. Mailgun costs $0.80 per 1000 emails at the moment.

### Backup/restore

The backup and restore scripts mentioned above will create and consume tarballs for migrating data in email accounts and on Nextcloud.