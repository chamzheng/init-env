#!/bin/bash
# set -v on
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PLAIN='\033[0m'

if [ $(uname) != "Linux" ];then
echo -e "\033[31m This script is only for Linux! \033[0m"
exit 1
fi

if [ -f /etc/redhat-release ]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
fi

setMirrors() {
    if [ $release == "ubuntu" ];then
        sudo sed -i 's|archive.ubuntu.com|mirrors.aliyun.com|g' /etc/apt/sources.list
        sudo sed -i 's|archive.ubuntu.com|mirrors.aliyun.com|g' /etc/apt/sources.list.d/*.list
        sudo sed -i 's|cn.archive.ubuntu.com|mirrors.aliyun.com|g' /etc/apt/sources.list
        sudo sed -i 's|cn.archive.ubuntu.com|mirrors.aliyun.com|g' /etc/apt/sources.list.d/*.list
        sudo sed -i '/security.ubuntu.com/d' /etc/apt/sources.list
        sudo sed -i '/security.ubuntu.com/d' /etc/apt/sources.list.d/*.list
    elif [ $release == "debian" ];then
        sudo sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list
        sudo sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/*.list
        sudo sed -i 's|security.debian.org/debian-security|mirrors.aliyun.com/debian-security|g' /etc/apt/sources.list
        sudo sed -i 's|security.debian.org/debian-security|mirrors.aliyun.com/debian-security|g' /etc/apt/sources.list.d/*.list
    elif [ $release == "centos" ];then
        echo "${YELLOW}This script does not support Centos replacement source!${PLAIN}"
    fi
    sudo apt update
    sudo apt upgrade -y
}

installBase() {
    sudo apt-get -y install htop wget curl git apt-transport-https ca-certificates gnupg-agent software-properties-common python3 python3-pip
    mkdir ~/.pip
    echo "[global]
index-url = https://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com" > ~/.pip/pip.conf
}

installZsh() {
    # 安装 zsh
    sudo apt-get -y install zsh
    sudo chsh -s /bin/zsh
    sudo sed -i 's|/bin/bash|/bin/zsh|g' /etc/passwd

    # 安装 oh-my-zsh
    sudo echo "199.232.4.133 raw.githubusercontent.com" >> /etc/hosts
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

    # 下载插件
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
    mv zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions.git
    mv zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

    # 替换插件列表
    sed -i 's|plugins=(git)|plugins=(zsh-autosuggestions git zsh-syntax-highlighting extract composer yarn npm)|g' ~/.zshrc

    # 替换主题
    sed -i 's|ZSH_THEME="robbyrussell"|ZSH_THEME="ys"|g' ~/.zshrc

    # 设置一些东西
    echo -e "export TERM=xterm-256color" >> ~/.zshrc
    echo -e "alias zshconfig=\"mate ~/.zshrc\"" >> ~/.zshrc
    echo -e "alias ohmyzsh=\"mate ~/.oh-my-zsh\"" >> ~/.zshrc

    # 立即生效
    source ~/.zshrc
}

installDocker() {
    sudo chmod +x ./install-docker.sh
    sudo sh ./install-docker.sh --mirror Aliyun
    sudo usermod -aG docker $USER

    # 安装 docker-compose
    sudo pip3 install docker-compose

    # 更新软件源
    sudo mkdir -p /etc/docker
    sudo echo "{" > /etc/docker/daemon.json
    sudo echo '  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]' >> /etc/docker/daemon.json
    sudo echo "}" >> /etc/docker/daemon.json
    sudo systemctl daemon-reload
    sudo systemctl restart docker
}

installSetup() {
    sudo cp -r ./wsl2-setup $HOME/.setup

    sudo chmod +x $HOME/.setup/enter-systemd-namespace.sh
    sudo chmod +x $HOME/.setup/start-systemd-namespace.sh
    sudo chmod +x $HOME/.setup/setup.sh

    sudo apt-get -y install daemonize dbus-user-session fontconfig

    sudo echo "
        Defaults        env_keep += WSLPATH
        Defaults        env_keep += WSLENV
        Defaults        env_keep += WSL_INTEROP
        Defaults        env_keep += WSL_DISTRO_NAME
        Defaults        env_keep += PRE_NAMESPACE_PATH
        Defaults        env_keep += PRE_NAMESPACE_PWD
        %sudo ALL=(ALL) NOPASSWD: $HOME/.setup/enter-systemd-namespace.sh
        " > /etc/sudoers.d/systemd-namespace

    sudo echo "%sudo ALL=(ALL) NOPASSWD: /usr/bin/sed" > /etc/sudoers.d/setup

    echo "source $HOME/.setup/setup.sh" >> $HOME/.zshrc
}

setMirrors
installBase
installZsh
installSetup
installDocker
