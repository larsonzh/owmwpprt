# owmwpprt
OpenWrt Multi WAN Port Policy Routing Tool

OpenWrt固件多WAN口策略路由分流工具

**v1.0.0**

本工具使用Shell脚本编写，可在OpenWrt固件的路由器上基于mwan3的强大功能，根据各网络运营商的互联网地址的分布，针对路由器上每个WAN口生成多个不同的目标网段数据集合，灵活绑定到mwan3的WAN口策略规则中，实现中国地区全网段的多WAN口数据流量分流控制策略。

脚本使用的所有ISP网络运营商CIDR网段数据源自clang苍狼山庄 https://ispip.clang.cn/ 整理的APNIC官方每日更新。

脚本作为mwan3的配套软件，使用前请到OpenWrt中的“Software”界面内搜索并下载安装如下软件：
    <ul><li>mwan3</li>
    <li>luci-app-mwan3</li>
    <li>luci-i18n-mwan3-zh-cn</li>
    <li>wget-ssl</li>
    <li>curl</li></ul>


**主要功能**

<ul><li>最多可支持8个WAN口的分流控制。</li>
<li>.可按如下10个网络运营商IPv4目标网段的划分配置路由器流量出口：</li>
    <ul><li>中国电信网段</li>
    <li>中国联通/网通网段</li>
    <li>中国移动网段</li>
    <li>中国铁通网段</li>
    <li>中国教育网网段</li>
    <li>长城宽带/鹏博士网段</li>
    <li>中国大陆其他运营商网段</li>
    <li>香港地区运营商网段</li>
    <li>澳门地区运营商网段</li>
    <li>台湾地区运营商网段</li></ul>
<li>可任意某个目标网段数据流量使用指定的路由器出口。</li>
<li>可设置某个目标网段数据流量由系统负载均衡自动分配流量出口。</li>
<li>可禁止某个网络运营商目标网段数据的使用。</li>
<li>可自动/手动下载更新所有网络运营商的CIDR网段数据。</li>
<li>可设定定时自动更新的时间及间隔。</li>
<li>可自动在系统计划任务中加载定时更新数据任务，无需人工手动添加。</li>
<li>可自动将脚本加载到系统启动项中，随路由器自动启动，无需人工手动添加。</li>
<li>脚本启动时可自动获取mwan3中设定的可用WAN口，并在终端中显示所设置的运营商网段对应的出口信息。</li>
<li>脚本启动时可自动侦测WAN口的内网IP、公网IP，并在终端中显示。</li>
<li>所有终端上显示输出的信息均同时写入系统日志，可随时在系统日志中查看。</li>
<li>提供脚本卸载数据命令，可将加载到系统启动项、计划任务，以及内存中的所有数据一次性卸载和清理干净。</li></ul>


**安装 & 操作**

一、设置路由器WAN口

在路由器“网络-接口”界面中按照设备实际情况配置两个及以上的WAN口。在WAN口设置页面中的“高级设置” 选项卡内，在 “使用网关跃点” 处，指定网关跃点，如10。第二个WAN口设置为11，以此类推，要求每一个WAN口的网关跃点数值唯一，不要有重复。网关跃点数值越小，优先级越高。

二、路由器连接互联网，按前文所述下载安装5个必须的支撑软件。

SSH终端下载命令
```markdown
        okpg update
        opkg install mwan3 luci-app-mwan3 luci-i18n-mwan3-zh-cn
        opkg install mwan3 wget-ssl
        opkg install mwan3 curl
```
三、设置mwan3

四、安装脚本软件

1.下载本工具的软件压缩包“lzrules-[version ID].tgz”（例如：lzrules-v1.0.0.tgz）。

2.使用WinSCP等工具将压缩包上传至路由器的任意目录。

3.在SSH终端中使用解压缩命令在当前目录中将软件解压缩，生成lzrules-[version ID]目录（例如：lzrules-v1.0.0），进入其中可看到一个lzrules目录，此为脚本的工作目录。
```markdown
        tar -xzvf lzvpns-[version ID].tgz
```
4.将lzrules目录复制或剪切粘贴到路由器中希望放置本脚本的位置，则完成本软件的安装。

5.在lzrules目录中，lzrules.sh为本工具的可执行脚本，若发现无运行权限，请赋予相关属性。data目录中保存的是10个网络运营商IPv4目标网段的数据文件，不要手工修改或删除。

五、脚本软件设置

