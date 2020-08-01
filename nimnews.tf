variable "fqdn" {
  description = "Fully qualified domain name"
}

resource "sys_file" "nimnews" {
  filename        = "/usr/local/bin/nimnews"
  source          = "https://github.com/mildred/nimnews/releases/download/latest-master/nimnews-latest-master"
  file_permission = 0755
}

resource "sys_file" "nimnews_socket" {
  filename = "/etc/systemd/system/nimnews.socket"
  content = <<CONF
[Unit]
Description=NimNews NNTP and NNTPS socket

[Socket]
ListenStream=[::]:119
ListenStream=[::]:563
BindIPv6Only=both

[Install]
WantedBy=multi-user.target

CONF
}

resource "sys_file" "nimnews_service" {
  filename = "/etc/systemd/system/nimnews.service"
  content = <<CONF
[Unit]
Description=NimNews server
After=network.target

[Service]
ExecStart=/usr/local/bin/nimnews \
  --port sd=0 --tls-port sd=1 \
  --db /var/lib/nimnews.sqlite \
  --fqdn ${var.fqdn} \
  --cert /etc/letsencrypt/live/${var.fqdn}/fullchain.pem \
  --skey /etc/letsencrypt/live/${var.fqdn}/privkey.pem \
  --lmtp-socket /run/nimnews-lmtp.socket \
  --smtp localhost \
  --log --smtp-debug

CONF
}

resource "sys_systemd_unit" "nimnews_socket" {
  name = "nimnews.socket"
  start = true
  enable = true
  restart_on = {
    unit = sys_file.nimnews_socket.id
  }
}

resource "sys_systemd_unit" "nimnews" {
  name = "nimnews.service"
  enable = false
  restart_on = {
    unit = sys_file.nimnews_service.id
    exec = sys_file.nimnews.id
  }
}

