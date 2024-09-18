#cloud-config
bootcmd:
  - |
    sudo apt update -y
    sudo apt install -y curl socat sqlite
    cd /root/
    wget https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz
    tar zxvf x-ui-linux-amd64.tar.gz
    chmod +x x-ui/x-ui x-ui/bin/xray-linux-* x-ui/x-ui.sh
    cp x-ui/x-ui.sh /usr/bin/x-ui
    cp -f x-ui/x-ui.service /etc/systemd/system/
    mv x-ui/ /usr/local/
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl restart x-ui

    sudo apt-get install certbot -y
    certbot certonly --standalone --agree-tos --register-unsafely-without-email -d labber.qianchen.tk >> /var/log/init.log 2>&1
    
