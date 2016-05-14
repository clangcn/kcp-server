KCP-Server
===========

##感谢[kcptun](https://github.com/xtaci/kcptun)提供这么优秀的软件
(kcptun是kcp协议的一个简单应用，可以用于任意tcp网络程序的传输承载，以提高网络流畅度，降低掉线情况。)
##感谢[koolshare](http://koolshare.cn/forum-72-1.html)的[小宝](http://koolshare.cn/space-uid-2380.html) 宝大的二次开发。

脚本是业余爱好，英文属于文盲，写的不好，不要笑话我，欢迎您批评指正。
安装平台：CentOS、Debian、Ubuntu。
Server
------

### Install

    wget --no-check-certificate https://github.com/clangcn/kcp-server/raw/master/install-kcp-server.sh -O ./install-kcp-server.sh
    chmod 500 ./install-kcp-server.sh
    ./install-kcp-server.sh install

### UnInstall

    ./install-kcp-server.sh uninstall

### Update

    ./install-kcp-server.sh update

### 服务器管理

    Usage: /etc/init.d/kcp-server {start|stop|restart|status}

### 多用户配置文件

    /usr/local/kcp-server/.kcp_server_config.sh
