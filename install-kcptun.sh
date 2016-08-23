#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  CentOS Debian or Ubuntu (32bit/64bit)
#   Description:  A tool to auto-compile & install kcptun on Linux
#   Author: Clang
#   Intro:  http://koolshare.cn/forum-72-1.html
#===============================================================================================
version="1.4"
str_program_dir="/usr/local/kcptun"
program_download_url=https://github.com/xtaci/kcptun/releases/download/
program_init_download_url=https://raw.githubusercontent.com/clangcn/kcp-server/master/kcptun.init
str_install_shell=https://raw.githubusercontent.com/clangcn/kcp-server/master/install-kcptun.sh

function fun_clang.cn(){
    echo ""
    echo "+-------------------------------------------------------+"
    echo "|       kcptun for Linux Server, Written by Clang       |"
    echo "+-------------------------------------------------------+"
    echo "|   A tool to auto-compile & install kcptun on Linux    |"
    echo "+-------------------------------------------------------+"
    echo "|       Intro: http://koolshare.cn/forum-72-1.html      |"
    echo "+-------------------------------------------------------+"
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
    ARCHS=""
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
        ARCHS="amd64"
    else
        Is_64bit='n'
        ARCHS="386"
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
            echo "serverport ${serverport}"
        fi
    else
        echo "Input error! Please input correct numbers."
        fun_input_port
    fi
}

# input port
function fun_input_port(){
    server_port="45678"
    echo ""
    echo -e "Please input Server Port [1-65535](Don't the same SSH Port ${COLOR_RED}${sshport}${COLOR_END})"
    read -p "(Default Server Port: ${server_port}):" serverport
    [ -z "${serverport}" ] && serverport="${server_port}"
    fun_check_port "${serverport}"
}
# Check port
function fun_check_mtu(){
    strInputMTU="$1"
    if [ ${strInputMTU} -ge 900 ] && [ ${strInputMTU} -le 1400 ]; then
        strInputMTU="${strInputMTU}"
        echo "mtu ${strInputMTU}"
    else
        echo "Input error! Please input correct numbers."
        fun_input_mtu
    fi
}

# input port
function fun_input_mtu(){
    def_mtu="1350"
    echo ""
    read -p "Please input mtu [900-1400],(Default mtu: ${def_mtu}):" strMTU
    [ -z "${strMTU}" ] && strMTU="${def_mtu}"
    fun_check_mtu "${strMTU}"
}
# ====== check packs ======
function check_nano(){
    nano -V >/dev/null
    if [[ $? -le 1 ]] ;then
        echo " Run nano success"
    else
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
function check_killall(){
    killall -V 2>/dev/null
    if [[ $? -gt 1 ]] ;then
        echo " Run killall failed"
        if [ "${OS}" == 'CentOS' ]; then
            echo " Install centos killall ..."
            yum -y install psmisc
        else
            echo " Install debian/ubuntu killall ..."
            apt-get update -y
            apt-get install -y psmisc
        fi
    fi
    echo $result
}
function fun_getVer(){
    kcptun_version=""
    echo "You can get version number from https://github.com/xtaci/kcptun/releases"
    read -p "(Please input kcptun Version you want[e.g.: 20160820]):" kcptun_version
    if [ "${kcptun_version}" = "" ]; then
        echo "Error: You must input kcptun_version version!!"
        exit 1
    fi
    echo "=================================================="
    echo -e "You want download version to ${COLOR_GREEN}${kcptun_version}${COLOR_END}"
    echo "=================================================="
    echo -e "${COLOR_YELOW}Press any key to start...or Press Ctrl+c to cancel${COLOR_END}"
    char=`get_char`
}
function fun_download_file(){
    if [ ! -s ${str_program_dir}/kcptun ]; then
        if ! wget --no-check-certificate ${program_download_url}v${kcptun_version}/kcptun-linux-${ARCHS}-${kcptun_version}.tar.gz; then
            echo "Failed to download kcptun-linux-${ARCHS}-${kcptun_version}.tar.gz file!"
            exit 1
        fi
    fi
    tar xzvf kcptun-linux-${ARCHS}-${kcptun_version}.tar.gz
    mv server_linux_${ARCHS} ${str_program_dir}/kcptun
    rm -f kcptun-linux-${ARCHS}-${kcptun_version}.tar.gz client_linux_${ARCHS}
    [ ! -x ${str_program_dir}/kcptun ] && chmod 755 ${str_program_dir}/kcptun
}
# ====== pre_install ======
function pre_install_clang(){
    fun_getVer
    #config setting
    sshport=`netstat -anp |grep ssh | grep '0.0.0.0:'|cut -d: -f2| awk 'NR==1 { print $1}'`
    #defIP=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.' | cut -d: -f2 | awk 'NR==1 { print $1}'`
    #if [ "${defIP}" = "" ]; then
        check_curl
        defIP=$(curl -s -4 ip.clang.cn | sed -r 's/\r//')
    #fi
    echo -e "You VPS IP:${COLOR_GREEN}${defIP}${COLOR_END}"
    echo " Please input your kcptun server_port"
    echo ""
    fun_input_port
    echo ""
    read -p "Please input shadow5ocks ip and port (e.g.: 127.0.0.1:8838):" redirect_addr_port
    if [ "${redirect_addr_port}" = "" ]; then
        echo "Error: You must input shadow5ocks ip and port!!"
        exit 1
    fi
    redirect_addr_port="${redirect_addr_port}"
    echo "shadow5ocks ip and port ${redirect_addr_port}"
    echo ""
    echo "##### Please select crypt mode #####"
    echo " 1: aes"
    echo " 2: aes-128"
    echo " 3: aes-192"
    echo " 4: salsa20"
    echo " 5: blowfish"
    echo " 6: twofish"
    echo " 7: cast5"
    echo " 8: 3des"
    echo " 9: tea"
    echo "10: xtea"
    echo "11: xor"
    echo " n: none"
    echo "#####################################################"
    read -p "Enter your choice (1, 2, 3, …… or exit. default [1]): " strcrypt
    case "${strcrypt}" in
        1|[aA][eE][sS])
            strcrypt="aes"
            ;;
        2|[aA][eE][sS]-128)
            strcrypt="aes-128"
            ;;
        3|[aA][eE][sS]-192)
            strcrypt="aes-192"
            ;;
        4|[sS][aA][lL][sS][aA]20)
            strcrypt="salsa20"
            ;;
        5|[bB][lL][oO][wW][fF][iI][sS][hH])
            strcrypt="blowfish"
            ;;
        6|[tT][wW][oO][fF][iI][sS][hH])
            strcrypt="twofish"
            ;;
        7|[cC][aA][sS][tT]5)
            strcrypt="cast5"
            ;;
        8|3[dD][eE][sS])
            strcrypt="3des"
            ;;
        9|[tT][eE][aA])
            strcrypt="tea"
            ;;
        10|[xX][tT][eE][aA])
            strcrypt="xtea"
            ;;
        11|[xX][oO][rR])
            strcrypt="xor"
            ;;
        12|[nN]|[nN][oO][nN][eE])
            strcrypt="none"
            ;;
        [eE][xX][iI][tT])
            exit 1
            ;;
        *)
            strcrypt="aes"
            ;;
    esac
    echo "crypt mode: ${strcrypt}"
    echo ""
    echo "##### Please select fast mode #####"
    echo "1: fast"
    echo "2: fast2"
    echo "3: fast3"
    echo "4: normal"
    echo "#####################################################"
    read -p "Enter your choice (1, 2, 3, 4 or exit. default [2]): " strmode
    case "${strmode}" in
        1|[fF][aA][sS][tT])
            strmode="fast"
            ;;
        2|[fF][aA][sS][tT]2)
            strmode="fast2"
            ;;
        3|[fF][aA][sS][tT]3)
            strmode="fast3"
            ;;
        4|[nN][oO][rR][mM][aA][lL])
            strmode="normal"
            ;;
        [eE][xX][iI][tT])
            exit 1
            ;;
        *)
            strmode="fast2"
            ;;
    esac
    echo "fast mode: ${strmode}"
    fun_input_mtu
    read -p "Please enable compression input Y, Disable compression input n,Default [yes]):" strcompression
    case "${strcompression}" in
    1|[yY]|[yY][eE][sS]|[tT][rR][uU][eE]|[eE][nN][aA][bB][lL][eE])
        strcompression="enable"
    ;;
    0|[nN]|[nN][oO]|[fF][aA][lL][sS][eE]|[dD][iI][sS][aA][bB][lL][eE])
        strcompression="disable"
    ;;
    *)
        strcompression="enable"
    esac
    echo "compression: ${strcompression}"
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
    echo -e "Server Port:${COLOR_GREEN}${serverport}${COLOR_END}"
    echo -e "redirect IPAddr and port:${COLOR_GREEN}${redirect_addr_port}${COLOR_END}"
    echo -e "crypt mode :${COLOR_GREEN}${strcrypt}${COLOR_END}"
    echo -e "fast mode :${COLOR_GREEN}${strmode}${COLOR_END}"
    echo -e "compression setting :${COLOR_GREEN}${strcompression}${COLOR_END}"
    echo -e "MTU setting :${COLOR_GREEN}${strInputMTU}${COLOR_END}"
    echo "=============================================="
    echo ""
    echo "Press any key to start...or Press Ctrl+c to cancel"

    char=`get_char`

    [ ! -d ${str_program_dir} ] && mkdir -p ${str_program_dir}
    cd ${str_program_dir}
    echo $PWD

# Config file
cat > ${str_program_dir}/.kcptun-config.sh<<-EOF
#!/bin/bash
# -------------config START-------------
listen_port="${serverport}"
redirect_addr_port="${redirect_addr_port}"
crypt="${strcrypt}"
mtu="${strInputMTU}"
sndwnd="1024"
rcvwnd="1024"
mode="${strmode}"
compression=${strcompression}
# -------------config END-------------
EOF
    chmod 500 ${str_program_dir}/.kcptun-config.sh
    rm -f ${str_program_dir}/kcptun
    fun_download_file
    if [ ! -s /etc/init.d/kcptun ]; then
        if ! wget --no-check-certificate ${program_init_download_url} -O /etc/init.d/kcptun; then
            echo "Failed to download kcptun.init file!"
            exit 1
        fi
    fi
    [ ! -x /etc/init.d/kcptun ] && chmod +x /etc/init.d/kcptun
    if [ "${OS}" == 'CentOS' ]; then
        chmod +x /etc/init.d/kcptun
        chkconfig --add kcptun
    else
        chmod +x /etc/init.d/kcptun
        update-rc.d -f kcptun defaults
    fi

    if [ "$set_iptables" == 'y' ]; then
        check_iptables
        # iptables config
        iptables -I INPUT -p udp --dport ${serverport} -j ACCEPT
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
    [ -s /etc/init.d/kcptun ] && ln -s /etc/init.d/kcptun /usr/bin/kcptun
    /etc/init.d/kcptun start
    ${str_program_dir}/kcptun --version
    echo ""
    fun_clang.cn
    #install successfully
    . ${str_program_dir}/.kcptun-config.sh
    case "${compression}" in
        0|[nN]|[nN][oO]|[fF][aA][lL][sS][eE]|[dD][iI][sS][aA][bB][lL][eE])
        nocomp=" --nocomp"
        ;;
        *)
        nocomp=""
        esac
    echo ""
    echo "Congratulations, kcptun install completed!"
    echo "=============================================="
    echo -e "Your Server IP:${COLOR_GREEN}${defIP}${COLOR_END}"
    echo -e "Server Port:${COLOR_GREEN}${listen_port}${COLOR_END}"
    echo -e "redirect IPAddr and port:${COLOR_GREEN}${redirect_addr_port}${COLOR_END}"
    echo -e "crypt mode :${COLOR_GREEN}${strcrypt}${COLOR_END}"
    echo -e "fast mode :${COLOR_GREEN}${strmode}${COLOR_END}"
    echo -e "compression setting :${COLOR_GREEN}${strcompression}${COLOR_END}"
    echo -e "MTU setting :${COLOR_GREEN}${mtu}${COLOR_END}"
    echo -e "sndwnd setting :${COLOR_GREEN}${sndwnd}${COLOR_END}"
    echo -e "rcvwnd setting :${COLOR_GREEN}${rcvwnd}${COLOR_END}"
    echo "=============================================="
    echo -e "Your Phone client config:${COLOR_GREEN}--crypt ${strcrypt} --mtu ${mtu} --sndwnd ${rcvwnd} --rcvwnd ${sndwnd} --mode ${strmode}${nocomp}${COLOR_END}"
    echo "=============================================="
    echo ""
    echo -e "kcptun status manage: ${COLOR_PINKBACK_WHITEFONT}/etc/init.d/kcptun${COLOR_END} {${COLOR_GREEN}start${COLOR_END}|${COLOR_PINK}stop${COLOR_END}|${COLOR_YELOW}restart${COLOR_END}}"
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
    if [ -s ${str_program_dir}/kcptun ] && [ -s /etc/init.d/kcptun ]; then
        echo "kcptun is installed!"
    else
        pre_install_clang
    fi
}
############################### configure function ##################################
function configure_program_server_clang(){
    check_nano
    if [ -s ${str_program_dir}/.kcptun-config.sh ]; then
        nano ${str_program_dir}/.kcptun-config.sh
    else
        echo "kcptun configuration file not found!"
    fi
}
############################### uninstall function ##################################
function uninstall_program_server_clang(){
    fun_clang.cn
    if [ -s /etc/init.d/kcptun ] || [ -s ${str_program_dir}/kcptun ] ; then
        echo "============== Uninstall kcptun =============="
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
        /etc/init.d/kcptun stop
        if [ "${OS}" == 'CentOS' ]; then
            chkconfig --del kcptun
        else
            update-rc.d -f kcptun remove
        fi
        rm -f /usr/bin/kcptun /etc/init.d/kcptun /var/run/kcptun.pid /root/kcptun-install.log /root/kcptun-update.log
        if [ "${save_config}" == 'n' ]; then
            rm -fr ${str_program_dir}
        else
            rm -f ${str_program_dir}/kcptun ${str_program_dir}/kcptun.log
        fi
        echo "kcptun uninstall success!"
    else
        echo "kcptun Not install!"
    fi
    echo ""
}
############################### update function ##################################
function update_program_server_clang(){
    fun_clang.cn
    check_curl
    if [ -s /etc/init.d/kcptun ] || [ -s ${str_program_dir}/kcptun ] ; then
        echo "============== Update kcptun =============="
        checkos
        check_centosversion
        check_os_bit
        remote_shell_version=`curl -s ${str_install_shell} | sed -n '/'^version'/p' | cut -d\" -f2`
        remote_init_version=`curl -s ${program_init_download_url} | sed -n '/'^version'/p' | cut -d\" -f2`
        local_init_version=`sed -n '/'^version'/p' /etc/init.d/kcptun | cut -d\" -f2`
        install_shell=${strPath}
        if [ ! -z ${remote_shell_version} ] || [ ! -z ${remote_init_version} ];then
            update_flag="false"
            if [[ "${version}" < "${remote_shell_version}" ]];then
                echo "========== Update kcptun install-kcptun.sh =========="
                if ! wget --no-check-certificate ${str_install_shell} -O ${install_shell}/install-kcptun.sh; then
                    echo "Failed to download install-kcptun.sh file!"
                    exit 1
                else
                    echo -e "${COLOR_GREEN}install-kcptun.sh Update successfully !!!${COLOR_END}"
                    update_flag="true"
                fi
            fi
            if [[ "${local_init_version}" < "${remote_init_version}" ]];then
                echo "========== Update kcptun /etc/init.d/kcptun =========="
                if ! wget --no-check-certificate ${program_init_download_url} -O /etc/init.d/kcptun; then
                    echo "Failed to download kcptun.init file!"
                    exit 1
                else
                    echo -e "${COLOR_GREEN}/etc/init.d/kcptun Update successfully !!!${COLOR_END}"
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
        if [ "${update_flag}" == 'false' ]; then
            [ ! -d ${str_program_dir} ] && mkdir -p ${str_program_dir}
            rm -f /usr/bin/kcptun ${str_program_dir}/kcptun
            fun_getVer
            check_killall
            killall kcptun
            sleep 1
            fun_download_file
            if [ "${OS}" == 'CentOS' ]; then
                chmod +x /etc/init.d/kcptun
                chkconfig --add kcptun
            else
                chmod +x /etc/init.d/kcptun
                update-rc.d -f kcptun defaults
            fi
            [ -s /etc/init.d/kcptun ] && ln -s /etc/init.d/kcptun /usr/bin/kcptun
            /etc/init.d/kcptun start
            ${str_program_dir}/kcptun -version
            echo "kcptun update success!"
        fi
    else
        echo "kcptun Not install!"
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
    install_program_server_clang 2>&1 | tee /root/kcptun-install.log
    ;;
config)
    configure_program_server_clang
    ;;
uninstall)
    uninstall_program_server_clang 2>&1 | tee /root/kcptun-uninstall.log
    ;;
update)
    update_program_server_clang 2>&1 | tee /root/kcptun-update.log
    ;;
*)
    fun_clang.cn
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall|update|config}"
    ;;
esac
