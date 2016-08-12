#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#======================================================================
#   System Required:  CentOS Debian or Ubuntu (32bit/64bit)
#   Description:  A tool to auto-compile & install kcp-Server on Linux
#   Author: Clang
#   Intro:  http://koolshare.cn/forum-72-1.html
#======================================================================
version="1.9"
str_program_dir="/usr/local/kcp-server"
program_download_url=https://raw.githubusercontent.com/clangcn/kcp-server/master/latest/
x64_file=server_linux_amd64
x86_file=server_linux_386
md5sum_file=md5sum.md
program_init_download_url=https://raw.githubusercontent.com/clangcn/kcp-server/master/kcp-server.init
str_install_shell=https://raw.githubusercontent.com/clangcn/kcp-server/master/install-kcp-server.sh

function fun_clang.cn(){
    echo ""
    echo "+-----------------------------------------------------------+"
    echo "|       kcp-Server for Linux Server, Written by Clang       |"
    echo "+-----------------------------------------------------------+"
    echo "|   A tool to auto-compile & install kcp-Server on Linux    |"
    echo "+-----------------------------------------------------------+"
    echo "|        Intro: http://koolshare.cn/forum-72-1.html         |"
    echo "+-----------------------------------------------------------+"
    echo ""
}

function fun_set_text_color(){
    COLOR_RED='\E[1;31m'
    COLOR_GREEN='\E[1;32m'
    COLOR_YELOW='\E[1;33m'
    COLOR_BLUE='\E[1;34m'
    COLOR_PINK='\E[1;35m'
    COLOR_PINKBACK_WHITEFONT='\033[45;37m'
    COLOR_END='\E[0m'
}
# Check if user is root
function rootness(){
    if [[ $EUID -ne 0 ]]; then
        fun_clang.cn
        echo "Error:This script must be run as root!" 1>&2
        exit 1
    fi
}

function get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

# Check OS
function checkos(){
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        OS=CentOS
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        OS=Debian
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        OS=Ubuntu
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}

# Get version
function getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

# CentOS version
function centosversion(){
    local code=$1
    local version="`getversion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi
}

# Check OS bit
function check_os_bit(){
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
    else
        Is_64bit='n'
    fi
}

function check_centosversion(){
if centosversion 5; then
    echo "Not support CentOS 5.x, please change to CentOS 6,7 or Debian or Ubuntu and try again."
    exit 1
fi
}

# Disable selinux
function disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

# Check port
function fun_check_port(){
    strServerPort="$1"
    if [ ${strServerPort} -ge 1 ] && [ ${strServerPort} -le 65535 ]; then
        checkServerPort=`netstat -ntulp | grep "\b:${strServerPort}\b"`
        if [ -n "${checkServerPort}" ]; then
            echo ""
            echo -e "${COLOR_RED}Error:${COLOR_END} Port ${COLOR_GREEN}${strServerPort}${COLOR_END} is ${COLOR_PINK}used${COLOR_END},view relevant port:"
            netstat -ntulp | grep "\b:${strServerPort}\b"
            fun_input_port
        else
            serverport="${strServerPort}"
        fi
    else
        echo "Input error! Please input correct numbers."
        fun_input_port
    fi
}

# input port
function fun_input_port(){
    server_port="8989"
    echo ""
    echo -e "Please input Server Port [1-65535](Don't the same SSH Port ${COLOR_RED}${sshport}${COLOR_END})"
    read -p "(Default Server Port: ${server_port}):" serverport
    [ -z "${serverport}" ] && serverport="${server_port}"
    fun_check_port "${serverport}"
}

# Random password
function fun_randstr(){
  index=0
  strRandomPass=""
  for i in {a..z}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {A..Z}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {0..9}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {1..16}; do strRandomPass="$strRandomPass${arr[$RANDOM%$index]}"; done
  echo $strRandomPass
}
# ====== check packs ======
function check_nano(){
    nano -V >/dev/null
    if [[ $? -gt 1 ]] ;then
        echo " Run nano failed"
        if [ "${OS}" == 'CentOS' ]; then
            echo " Install centos nano ..."
            yum -y install nano
        else
            echo " Install debian/ubuntu nano ..."
            apt-get update -y
            apt-get install -y nano
        fi
    fi
    echo $result
}
function check_net-tools(){
    netstat -V >/dev/null
    if [[ $? -gt 6 ]] ;then
        echo " Run net-tools failed"
        if [ "${OS}" == 'CentOS' ]; then
            echo " Install centos net-tools ..."
            yum -y install net-tools
        else
            echo " Install debian/ubuntu net-tools ..."
            apt-get update -y
            apt-get install -y net-tools
        fi
    fi
    echo $result
}
function check_md5sum(){
    md5sum --version >/dev/null
    if [[ $? -gt 6 ]] ;then
        echo " Run md5sum failed"
    fi
    echo $result
}
function check_iptables(){
    iptables -V >/dev/null
    if [[ $? -gt 1 ]] ;then
        echo " Run iptables failed"
        if [ "${OS}" == 'CentOS' ]; then
            echo " Install centos iptables ..."
            yum -y install iptables policycoreutils libpcap libpcap-devel
        else
            echo " Install debian/ubuntu iptables ..."
            apt-get update -y
            apt-get install -y iptables libpcap-dev
        fi
    fi
    echo $result
}
function check_curl(){
    curl -V >/dev/null
    if [[ $? -gt 1 ]] ;then
        echo " Run curl failed"
        if [ "${OS}" == 'CentOS' ]; then
            echo " Install centos curl ..."
            yum -y install curl curl-devel
        else
            echo " Install debian/ubuntu curl ..."
            apt-get update -y
            apt-get install -y curl
        fi
    fi
    echo $result
}
function fun_download_file(){
    program_file=""
    if [ "${Is_64bit}" == 'y' ] ; then
        program_file=${x64_file}
        if [ ! -s ${str_program_dir}/kcp-server ]; then
            if ! wget --no-check-certificate ${program_download_url}${program_file} -O ${str_program_dir}/kcp-server; then
                echo "Failed to download kcp-server file!"
                exit 1
            fi
        fi
    else
        program_file=${x86_file}
        if [ ! -s ${str_program_dir}/kcp-server ]; then
            if ! wget --no-check-certificate ${program_download_url}${program_file} -O ${str_program_dir}/kcp-server; then
                echo "Failed to download kcp-server file!"
                exit 1
            fi
        fi
    fi
    check_curl
    check_md5sum
    md5_web=`curl -s ${program_download_url}${md5sum_file} | sed  -n "/${program_file}/p" | awk '{print $1}'`
    local_md5=`md5sum ${str_program_dir}/kcp-server | awk '{print $1}'`
    if [ "${local_md5}" != "${md5_web}" ]; then
        echo "md5sum not match,Failed to download kcp-server file!"
        exit 1
    fi
    [ ! -x ${str_program_dir}/kcp-server ] && chmod 755 ${str_program_dir}/kcp-server
}
# ====== pre_install ======
function pre_install_clang(){
    #config setting
    sshport=`netstat -anp |grep ssh | grep '0.0.0.0:'|cut -d: -f2| awk 'NR==1 { print $1}'`
    #defIP=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.' | cut -d: -f2 | awk 'NR==1 { print $1}'`
    #if [ "${defIP}" = "" ]; then
        check_curl
        defIP=$(curl -s -4 ip.clang.cn | sed -r 's/\r//')
    #fi
    echo -e "You VPS IP:${COLOR_GREEN}${defIP}${COLOR_END}"
    echo " Please input your kcp-Server server_port and password"
    echo ""
    fun_input_port
    echo ""
    server_pwd=`fun_randstr`
    read -p "Please input Password (Default Password: ${server_pwd}):" serverpwd
    if [ "${serverpwd}" = "" ]; then
        serverpwd="${server_pwd}"
    fi
    echo ""
    set_iptables="n"
        echo  -e "\033[33mDo you want to set iptables?\033[0m"
        read -p "(if you want please input: y,Default [no]):" set_iptables

        case "${set_iptables}" in
        [yY]|[yY][eE][sS])
        echo "You will set iptables!"
        set_iptables="y"
        ;;
        [nN]|[nN][oO])
        echo "You will NOT set iptables!"
        set_iptables="n"
        ;;
        *)
        echo "The iptables is not set!"
        set_iptables="n"
        esac

    echo ""
    echo "============== Check your input =============="
    echo -e "Your Server IP:${COLOR_GREEN}${defIP}${COLOR_END}"
    echo -e "Your Server Port:${COLOR_GREEN}${serverport}${COLOR_END}"
    echo -e "Your Password:${COLOR_GREEN}${serverpwd}${COLOR_END}"
    echo "=============================================="
    echo ""
    echo "Press any key to start...or Press Ctrl+c to cancel"

    char=`get_char`

    echo "============== Install packs =============="
    if [ "${OS}" == 'CentOS' ]; then
        #yum -y update
        yum -y install wget psmisc
    else
        apt-get update -y
        apt-get install -y wget psmisc
    fi

    [ ! -d ${str_program_dir} ] && mkdir -p ${str_program_dir}
    cd ${str_program_dir}
    echo $PWD

# Config file
cat > ${str_program_dir}/config.json<<-EOF
{
    "server":"0.0.0.0",
    "redir_port":0,
    "mode":"fast2",
    "sndwnd":1024,
    "rcvwnd":1024,
    "mtu":1350,
    "nocomp": false,
    "port_password":
    {
        "${serverport}": "${serverpwd}"
    },
    "_comment":
    {
        "${serverport}": "The server port comment"
    }
}
EOF
cat > ${str_program_dir}/client.json<<-EOF
{
    "server":"${defIP}",
    "server_port":${serverport},
    "password":"${serverpwd}",
    "socks5_port":1080,
    "redir_port":0,
    "mode":"fast2",
    "sndwnd":128,
    "rcvwnd":1024,
    "mtu":1350,
    "nocomp": false
}
EOF
    chmod 400 ${str_program_dir}/config.json
    rm -f ${str_program_dir}/kcp-server
    fun_download_file
    if [ ! -s /etc/init.d/kcp-server ]; then
        if ! wget --no-check-certificate ${program_init_download_url} -O /etc/init.d/kcp-server; then
            echo "Failed to download kcp-server.init file!"
            exit 1
        fi
    fi
    [ ! -x /etc/init.d/kcp-server ] && chmod +x /etc/init.d/kcp-server
    if [ "${OS}" == 'CentOS' ]; then
        chmod +x /etc/init.d/kcp-server
        chkconfig --add kcp-server
    else
        chmod +x /etc/init.d/kcp-server
        update-rc.d -f kcp-server defaults
    fi

    if [ "$set_iptables" == 'y' ]; then
        check_iptables
        # iptables config
        iptables -I INPUT -p udp --dport ${serverport} -j ACCEPT
        iptables -I INPUT -p tcp --dport ${serverport} -j ACCEPT
        iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        if [ "${OS}" == 'CentOS' ]; then
            service iptables save
        else
            echo '#!/bin/bash' > /etc/network/if-post-down.d/iptables
            echo 'iptables-save > /etc/iptables.rules' >> /etc/network/if-post-down.d/iptables
            echo 'exit 0;' >> /etc/network/if-post-down.d/iptables
            chmod +x /etc/network/if-post-down.d/iptables

            echo '#!/bin/bash' > /etc/network/if-pre-up.d/iptables
            echo 'iptables-restore < /etc/iptables.rules' >> /etc/network/if-pre-up.d/iptables
            echo 'exit 0;' >> /etc/network/if-pre-up.d/iptables
            chmod +x /etc/network/if-pre-up.d/iptables
        fi
    fi
    [ -s /etc/init.d/kcp-server ] && ln -s /etc/init.d/kcp-server /usr/bin/kcp-server
    /etc/init.d/kcp-server start
    ${str_program_dir}/kcp-server --version
    strMTU=`sed -n '/'mtu'/p' ${str_program_dir}/config.json | cut -d : -f2 | cut -d , -f1`
    echo ""
    fun_clang.cn
    #install successfully
    echo ""
    echo "Congratulations, kcp-Server install completed!"
    echo -e "Your Server IP:${COLOR_GREEN}${defIP}${COLOR_END}"
    echo -e "Your Server Port:${COLOR_GREEN}${serverport}${COLOR_END}"
    echo -e "Your Password:${COLOR_GREEN}${serverpwd}${COLOR_END}"
    echo -e "Your MTU:${COLOR_GREEN}${strMTU}${COLOR_END}"
    # echo -e "Your Local Port:${COLOR_GREEN}1080${COLOR_END}"
    echo ""
    echo -e "kcp-Server status manage: ${COLOR_PINKBACK_WHITEFONT}/etc/init.d/kcp-server${COLOR_END} {${COLOR_GREEN}start${COLOR_END}|${COLOR_PINK}stop${COLOR_END}|${COLOR_YELOW}restart${COLOR_END}}"
}
############################### install function ##################################
function install_program_server_clang(){
    fun_clang.cn
    checkos
    check_centosversion
    check_os_bit
    disable_selinux
    clear
    fun_clang.cn
    check_net-tools
    if [ -s ${str_program_dir}/kcp-server ] && [ -s /etc/init.d/kcp-server ]; then
        echo "kcp-Server is installed!"
    else
        pre_install_clang
    fi
}
############################### configure function ##################################
function configure_program_server_clang(){
    check_nano
    if [ -s ${str_program_dir}/config.json ]; then
        nano ${str_program_dir}/config.json
    else
        echo "kcp-Server configuration file not found!"
    fi
}
############################### uninstall function ##################################
function uninstall_program_server_clang(){
    fun_clang.cn
    if [ -s /etc/init.d/kcp-server ] || [ -s ${str_program_dir}/kcp-server ] ; then
        echo "============== Uninstall kcp-Server =============="
        save_config="n"
        echo  -e "${COLOR_YELOW}Do you want to keep the configuration file?${COLOR_END}"
        read -p "(if you want please input: y,Default [no]):" save_config

        case "${save_config}" in
        [yY]|[yY][eE][sS])
        echo ""
        echo "You will keep the configuration file!"
        save_config="y"
        ;;
        [nN]|[nN][oO])
        echo ""
        echo "You will NOT to keep the configuration file!"
        save_config="n"
        ;;
        *)
        echo ""
        echo "will NOT to keep the configuration file!"
        save_config="n"
        esac
        checkos
        /etc/init.d/kcp-server stop
        if [ "${OS}" == 'CentOS' ]; then
            chkconfig --del kcp-server
        else
            update-rc.d -f kcp-server remove
        fi
        rm -f /usr/bin/kcp-server /etc/init.d/kcp-server /var/run/kcp-server.pid /root/kcp-server-install.log /root/kcp-server-update.log
        if [ "${save_config}" == 'n' ]; then
            rm -fr ${str_program_dir}
        else
            rm -f ${str_program_dir}/kcp-server ${str_program_dir}/kcp-server.log
        fi
        echo "kcp-Server uninstall success!"
    else
        echo "kcp-Server Not install!"
    fi
    echo ""
}
############################### update function ##################################
function update_program_server_clang(){
    fun_clang.cn
    check_curl
    if [ -s /etc/init.d/kcp-server ] || [ -s ${str_program_dir}/kcp-server ] ; then
        echo "============== Update kcp-Server =============="
        checkos
        check_centosversion
        check_os_bit
        killall kcp-server
        remote_shell_version=`curl -s ${str_install_shell} | sed -n '/'^version'/p' | cut -d\" -f2`
        remote_init_version=`curl -s ${program_init_download_url} | sed -n '/'^version'/p' | cut -d\" -f2`
        local_init_version=`sed -n '/'^version'/p' /etc/init.d/kcp-server | cut -d\" -f2`
        install_shell=${strPath}
        if [ ! -z ${remote_shell_version} ] || [ ! -z ${remote_init_version} ];then
            update_flag="false"
            if [[ "${version}" < "${remote_shell_version}" ]];then
                echo "========== Update kcp-Server install-kcp-server.sh =========="
                if ! wget --no-check-certificate ${str_install_shell} -O ${install_shell}/install-kcp-server.sh; then
                    echo "Failed to download install-kcp-server.sh file!"
                    exit 1
                else
                    echo -e "${COLOR_GREEN}install-kcp-server.sh Update successfully !!!${COLOR_END}"
                    update_flag="true"
                fi
            fi
            if [[ "${local_init_version}" < "${remote_init_version}" ]];then
                echo "========== Update kcp-Server /etc/init.d/kcp-server =========="
                if ! wget --no-check-certificate ${program_init_download_url} -O /etc/init.d/kcp-server; then
                    echo "Failed to download kcp-server.init file!"
                    exit 1
                else
                    echo -e "${COLOR_GREEN}/etc/init.d/kcp-server Update successfully !!!${COLOR_END}"
                    update_flag="true"
                fi
            fi
            if [ "${update_flag}" == 'true' ]; then
                echo -e "${COLOR_GREEN}Update shell successfully !!!${COLOR_END}"
                echo ""
                echo -e "${COLOR_GREEN}Please Re-run${COLOR_END} ${COLOR_PINKBACK_WHITEFONT}$0 update${COLOR_END}"
                echo ""
                exit 1
            fi
        fi
        [ ! -d ${str_program_dir} ] && mkdir -p ${str_program_dir}
        rm -f /usr/bin/kcp-server ${str_program_dir}/kcp-server
        fun_download_file
        if [ "${OS}" == 'CentOS' ]; then
            chmod +x /etc/init.d/kcp-server
            chkconfig --add kcp-server
        else
            chmod +x /etc/init.d/kcp-server
            update-rc.d -f kcp-server defaults
        fi
        [ -s /etc/init.d/kcp-server ] && ln -s /etc/init.d/kcp-server /usr/bin/kcp-server
        /etc/init.d/kcp-server start
        ${str_program_dir}/kcp-server -version
        echo "kcp-Server update success!"
    else
        echo "kcp-Server Not install!"
    fi
    echo ""
}
clear
strPath=`pwd`
rootness
fun_set_text_color
# Initialization
action=$1
[  -z $1 ]
case "$action" in
install)
    install_program_server_clang 2>&1 | tee /root/kcp-server-install.log
    ;;
config)
    configure_program_server_clang
    ;;
uninstall)
    uninstall_program_server_clang 2>&1 | tee /root/kcp-server-uninstall.log
    ;;
update)
    update_program_server_clang 2>&1 | tee /root/kcp-server-update.log
    ;;
*)
    fun_clang.cn
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall|update|config}"
    ;;
esac
