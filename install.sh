#!/bin/bash
export LC_ALL=C
re="\033[0m"
red="\033[1;91m"
green="\e[1;32m"
yellow="\e[1;33m"
purple="\e[1;35m"
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
reading() { read -p "$(red "$1")" "$2"; }
HOSTNAME=$(hostname)
USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
export DOMAIN=${DOMAIN:-''}

if [[ -z "$DOMAIN" ]]; then
    if [[ "$HOSTNAME" =~ ct8 ]]; then
        CURRENT_DOMAIN="${USERNAME}.ct8.pl"
    elif [[ "$HOSTNAME" =~ hostuno ]]; then
        CURRENT_DOMAIN="${USERNAME}.useruno.com"
    else
        CURRENT_DOMAIN="${USERNAME}.serv00.net"
    fi
else
    CURRENT_DOMAIN="$DOMAIN"
fi

WORKDIR="${HOME}/domains/${CURRENT_DOMAIN}/public_nodejs"
[[ -d "$WORKDIR" ]] && mkdir -p "$WORKDIR" && chmod 777 "$WORKDIR"  >/dev/null 2>&1
command -v curl &>/dev/null && COMMAND="curl -so" || command -v wget &>/dev/null && COMMAND="wget -qO" || { red "Error: neither curl nor wget found, please install one of them." >&2; exit 1; }

check_website() {
yellow "正在安装中,请稍等...\n"
CURRENT_SITE=$(devil www list | awk -v domain="$CURRENT_DOMAIN" '$1 == domain && $2 == "nodejs"')
if [ -n "$CURRENT_SITE" ]; then
    green "已存在 ${CURRENT_DOMAIN} 站点\n"s
else
    EXIST_SITE=$(devil www list | awk -v domain="$CURRENT_DOMAIN" '$1 == domain')
    
    if [ -n "$EXIST_SITE" ]; then
        devil www del "$CURRENT_DOMAIN" >/dev/null 2>&1
        devil www add "$CURRENT_DOMAIN" nodejs /usr/local/bin/node22 > /dev/null 2>&1
        green "已删除旧的站点并创建新的站点\n"
    else
        devil www add "$CURRENT_DOMAIN" nodejs /usr/local/bin/node22 > /dev/null 2>&1
        green "已创建站点 ${CURRENT_DOMAIN}\n"
    fi
fi
}

apply_configure() {
    DOWNLOAD_URL="https://github.com/saodisengyyds/nav-item-ct8/releases/download/v1.0.0/nav_with_data_import_export.tar.gz"
    $COMMAND "${WORKDIR}/nav.zip" "$DOWNLOAD_URL"
    ln -fs /usr/local/bin/node22 ~/bin/node > /dev/null 2>&1
    ln -fs /usr/local/bin/npm22 ~/bin/npm > /dev/null 2>&1
    mkdir -p ~/.npm-global > /dev/null 2>&1
    npm config set prefix '~/.npm-global' > /dev/null 2>&1
    echo 'export PATH=~/.npm-global/bin:~/bin:$PATH' >> $HOME/.bash_profile && source $HOME/.bash_profile
    rm -rf $HOME/.npmrc > /dev/null 2>&1
    cd ${WORKDIR} && rm -rf public > /dev/null 2>&1
    if [ -e "${WORKDIR}/nav.zip" ]; then
        tar -xzf ${WORKDIR}/nav.zip -C ${WORKDIR} > /dev/null 2>&1
        rm -rf ${WORKDIR}/nav.zip
        yellow "正在安装依赖,请稍等...\n"
        npm install -r package.json --silent > /dev/null 2>&1
    fi
    devil www restart ${CURRENT_DOMAIN} > /dev/null 2>&1
}

show_info(){
if [[ -z "$DOMAIN" ]]; then
    if curl -o /dev/null -s -w "%{http_code}\n" https://${CURRENT_DOMAIN} | grep -q 200; then
        green "导航站已安装成功,相关信息如下:\n"
    else
        red "站点 ${CURRENT_DOMAIN} 无法访问,请重置系统后重装"
    fi
else
    ip_address=$(devil vhost list | awk '$2 ~ /web/ {print $1}')
    purple "请将 ${yellow}${CURRENT_DOMAIN} ${purple}域名在cloudflared添加A记录指向 ${yellow}$ip_address ${purple}并开启小黄云,再访问站点检查是否正常${re}\n\n"
fi

echo -e "${green}站点链接：${re}${purple}https://${CURRENT_DOMAIN}${re}\n"
echo -e "${green}后台管理入口：${re}${purple}https://${CURRENT_DOMAIN}/admin${re}\n"
echo -e "${green}后台管理账号：${re}${purple}admin${re}\n"
echo -e "${green}后台管理密码：${re}${purple}123456${re}\n"
red "温馨提示：请及时进入后台修改密码\n"

yellow "\n\nServ00|ct8|hostuno老王导航站一键安装脚本\n"
echo -e "${green}TG反馈群组：${re}${yellow}https://t.me/eooceu${re}\n"
echo -e "${green}Youtube频道：${re}${yellow}https://youtube.com/@eooce${re}\n"
echo -e "${green}项目地址：${re}${yellow}https://github.com/eooce/nav-item${re}\n"
}

install_nav() {
    check_website
    apply_configure
    show_info
}
install_nav