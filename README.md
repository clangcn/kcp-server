KCP-Server
===========

##感谢[kcptun](https://github.com/xtaci/kcptun)提供这么优秀的软件
kcptun是kcp协议的一个简单应用，可以用于任意tcp网络程序的传输承载，以提高网络流畅度，降低掉线情况。
##感谢[koolshare](http://koolshare.cn/forum-72-1.html)的[小宝](http://koolshare.cn/space-uid-2380.html) 宝大提醒配置的方法。

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

### 多用户配置文件示例

    {
        "server":"0.0.0.0",
        "socks5_port":9081,
        "redir_port":0,
        "tuncrypt":0,
        "sndwnd":128,
        "rcvwnd":1024,
        "mtu":1450,
        "mode":"fast",
        {
            "端口1": "密码1",
            "端口2": "密码2",
            "端口3": "密码3",
            "端口4": "密码4",
            "端口5": "密码5"
        },
        "_comment":
        {
            "端口1": "端口描述1",
            "端口2": "端口描述2",
            "端口3": "端口描述3",
            "端口4": "端口描述4",
            "端口5": "端口描述5"
        }
    }

### 客户端配置文件示例

    {
        "server":"你服务器IP地址",
        "server_port":服务器端口,
        "password":"端口对应的密码",
        "socks5_port":1080,
        "redir_port":0,
        "tuncrypt":0,
        "sndwnd":128,
        "rcvwnd":1024,
        "mtu":1450,
        "mode":"fast"
    }
