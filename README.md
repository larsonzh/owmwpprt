# owmwpprt
OpenWrt Multi WAN Port Policy Routing Tool

OpenWrt固件多WAN口策略路由分流工具

**v1.0.0**

本工具使用Shell脚本编写，可在OpenWrt固件的路由器上基于mwan3的强大功能，根据各网络运营商的互联网地址的分布，针对路由器上每个WAN口生成多个不同的目标网段数据集合，灵活绑定到mwan3的WAN口策略规则中，实现中国地区全网段的多WAN口数据流量分流控制策略。

**主要功能**

<ul><li>1.最多可支持8个WAN口的分流控制。</li>
<li>2.可按如下10个网络运营商IPv4目标网段的划分分配路由器流量出口：</li>
    <ul><li>1.中国电信网段</li>
    <li>2.中国联通/网通网段</li>
    <li>3.中国移动网段</li>
    <li>4.中国铁通网段</li>
    <li>5.中国教育网网段</li>
    <li>6.长城宽带/鹏博士网段</li>
    <li>7.中国大陆其他运营商网段</li>
    <li>8.香港地区运营商网段</li>
    <li>9.澳门地区运营商网段</li>
    <li>10.台湾地区运营商网段</li></ul>
<li>3.可任意设置上述某个待访问网络运营商目标网段的数据流量使用指定的路由器出口。</li>
<li>4.可任意设置上述某个待访问网络运营商目标网段的数据流量由系统采用负载均衡技术自动分配流量出口。</li>
<li>5.可禁止任意个网络运营商目标网段数据的使用。</li>
<li>6.可自动下载更新上述所有ISP网络运营商CIDR网段数据。</li>
<li>7.可自动在系统计划任务中加载定时更新数据任务，无需人工手动添加。</li>
<li>8.可自动将脚本加载到系统启动项中，无需人工手动添加。</li>
<li>9.脚本启动时可自动获取mwan3中设定的可用WAN口，并显示所设置的运营商网段对应出口信息。</li>
<li>10.脚本启动时可自动侦测WAN口的内网IP、公网IP，并在终端中显示。</li>
<li>11.所有终端上显示输出的信息均同时写入系统日志，可随时在系统日志中查看。</li>
<li>12.提供脚本卸载数据命令，可将在系统启动项、计划任务，以及内存中加载的所有数据一次性卸载和清理干净。</li></ul>

