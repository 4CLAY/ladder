#cloud-config
bootcmd:
  - |
    sudo apt update -y
    sudo apt install -y curl socat
    
