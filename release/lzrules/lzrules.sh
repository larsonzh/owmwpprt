#!/bin/sh
# lzrules.sh v2.2.0
# By LZ 妙妙呜 (larsonzhang@gmail.com)

# LZ RULES script for OpenWrt based router

# 脚本命令 (假设当前在 lzrules 目录)
# 加载规则数据         ./lzrules.sh
# 更新数据文件         ./lzrules.sh update
# 卸载运行数据         ./lzrules.sh unload

# OpenWrt 多 WAN 口策略路由分流脚本

# 使用说明：
# 1. 脚本作为 mwan3 的配套软件使用，请提前到 OpenWrt 中的「Software」界面内搜索并下载安装如下软件包：
#     mwan3
#     luci-app-mwan3
#     luci-i18n-mwan3-zh-cn
#     iptables-nft
#     ip6tables-nft
#     wget-ssl
#     dnsmasq-full
#    注：dnsmasq-full 安装前需卸载删除原有的 dnsmasq 软件包。
# 2. 路由器上的 WAN 口是本地网络连接外部广域网络的通信接口。脚本中的 WAN 口不是用户定义和命名的逻辑接口，而是路由器
#    设备上实际的物理网卡接口，或是在网卡设备上定义的 VLAN 子接口。用户在 network 文件或 OpenWrt「网络 - 接口」页面
#    中配置网络接口时，DHCP 客户端、DHCPv6 客户端、PPP、PPPoE、静态地址等相同或不同协议的多个逻辑接口，可以共享使用
#    同一个 WAN 口。在 network 文件或 OpenWrt「网络 - 接口」页面中，排除掉所有本地网络及回环设备后，按照每个物理网卡
#    接口（或 VLAN 子接口）设备，从上到下首次被某个逻辑接口使用或关联时所构成的先后顺序，所有 WAN 口升序排列为「第一 
#    WAN 口」至「第八 WAN 口」，出口参数对应为 0 ~ 7。
# 3. 脚本已涵盖中国地区所有运营商 IPv4/IPv6 目标网段，访问国外的流量出口在「MultiWAN 管理器」中配置出口策略规则。
# 4. 在脚本中配置完流量出口后，需在「MultiWAN 管理器 - 规则」界面内，将 WAN 口数据集合名称（如：ISPIP_SET_0），填
#    入相应 WAN 口策略规则条目中的「IP 配置」字段内。填写时，在下拉框中选择「自定义」，在输入框中书写完毕后按回车键，
#    即可完成数据集合名称的输入。卸载脚本时，请在下拉框中选择「--请选择--」项，然后按页面中的「保存」，最后在「规
#    则」界面中「保存并应用」，就可以解除该 WAN 口数据集合与相应规则的绑定关系。
# 5. 脚本适用于 OpenWrt 22.03.7 及以前版本的部分原生固件。更早版本或第三方编译制作的固件未经测试，也可能不支持。

# BEGIN

# shellcheck disable=SC2034  # Unused variables left for readability


# ----------------用户运行策略自定义区----------------

# 中国电信 IPv4/IPv6 目标网段客户端流量（网段数据文件：chinatelecom_cidr.txt/chinatelecom_ipv6.txt）
# 0 -- 第一 WAN 口；1 -- 第二 WAN 口；···；7 -- 第八 WAN 口；8 -- 负载均衡；9 -- 未知流量（mwan3 中设置处理）；取值范围：0 ~ 9
# 缺省：IPv4 流量 -- 第一 WAN 口（0）；IPv6 流量 -- 未知流量（9）。
ISP_0_WAN_PORT=0
ISP_0_WAN_PORT_V6=9

# 中国联通/网通 IPv4/IPv6 目标网段客户端流量（网段数据文件：unicom_cnc_cidr.txt/unicom_cnc_ipv6.txt）
# 0 -- 第一 WAN 口；1 -- 第二 WAN 口；···；7 -- 第八 WAN 口；8 -- 负载均衡；9 -- 未知流量（mwan3 中设置处理）；取值范围：0 ~ 9
# 缺省：IPv4 流量 -- 第一 WAN 口（0）；IPv6 流量 -- 未知流量（9）。
ISP_1_WAN_PORT=0
ISP_1_WAN_PORT_V6=9

# 中国移动 IPv4/IPv6 目标网段客户端流量（网段数据文件：cmcc_cidr.txt/cmcc_ipv6.txt）
# 0 -- 第一 WAN 口；1 -- 第二 WAN 口；···；7 -- 第八 WAN 口；8 -- 负载均衡；9 -- 未知流量（mwan3 中设置处理）；取值范围：0 ~ 9
# 缺省：IPv4 流量 -- 第二 WAN 口（1）；IPv6 流量 -- 未知流量（9）。
ISP_2_WAN_PORT=1
ISP_2_WAN_PORT_V6=9

# 中国铁通 IPv4/IPv6 目标网段客户端流量（网段数据文件：crtc_cidr.txt/crtc_ipv6.txt）
# 0 -- 第一 WAN 口；1 -- 第二 WAN 口；···；7 -- 第八 WAN 口；8 -- 负载均衡；9 -- 未知流量（mwan3 中设置处理）；取值范围：0 ~ 9
# 缺省：IPv4 流量 -- 第二 WAN 口（1）；IPv6 流量 -- 未知流量（9）。
ISP_3_WAN_PORT=1
ISP_3_WAN_PORT_V6=9

# 中国教育网 IPv4/IPv6 目标网段客户端流量（网段数据文件：cernet_cidr.txt/cernet_ipv6.txt）
# 0 -- 第一 WAN 口；1 -- 第二 WAN 口；···；7 -- 第八 WAN 口；8 -- 负载均衡；9 -- 未知流量（mwan3 中设置处理）；取值范围：0 ~ 9
# 缺省：IPv4 流量 -- 第二 WAN 口（1）；IPv6 流量 -- 未知流量（9）。
ISP_4_WAN_PORT=1
ISP_4_WAN_PORT_V6=9

# 长城宽带/鹏博士 IPv4/IPv6 目标网段客户端流量（网段数据文件：gwbn_cidr.txt/gwbn_ipv6.txt）
# 0 -- 第一 WAN 口；1 -- 第二 WAN 口；···；7 -- 第八 WAN 口；8 -- 负载均衡；9 -- 未知流量（mwan3 中设置处理）；取值范围：0 ~ 9
# 缺省：IPv4 流量 -- 第二 WAN 口（1）；IPv6 流量 -- 未知流量（9）。
ISP_5_WAN_PORT=1
ISP_5_WAN_PORT_V6=9

# 中国大陆其他运营商 IPv4/IPv6 目标网段客户端流量（网段数据文件：othernet_cidr.txt/othernet_ipv6.txt）
# 0 -- 第一 WAN 口；1 -- 第二 WAN 口；···；7 -- 第八 WAN 口；8 -- 负载均衡；9 -- 未知流量（mwan3 中设置处理）；取值范围：0 ~ 9
# 缺省：IPv4 流量 -- 第二 WAN 口（0）；IPv6 流量 -- 未知流量（9）。
ISP_6_WAN_PORT=0
ISP_6_WAN_PORT_V6=9

# 香港地区运营商 IPv4/IPv6 目标网段客户端流量（网段数据文件：hk_cidr.txt/hk_ipv6.txt）
# 0 -- 第一 WAN 口；1 -- 第二 WAN 口；···；7 -- 第八 WAN 口；8 -- 负载均衡；9 -- 未知流量（mwan3 中设置处理）；取值范围：0 ~ 9
# 缺省：IPv4 流量 -- 第二 WAN 口（0）；IPv6 流量 -- 未知流量（9）。
ISP_7_WAN_PORT=0
ISP_7_WAN_PORT_V6=9

# 澳门地区运营商 IPv4/IPv6 目标网段客户端流量（网段数据文件：mo_cidr.txt/mo_ipv6.txt）
# 0 -- 第一 WAN 口；1 -- 第二 WAN 口；···；7 -- 第八 WAN 口；8 -- 负载均衡；9 -- 未知流量（mwan3 中设置处理）；取值范围：0 ~ 9
# 缺省：IPv4 流量 -- 第二 WAN 口（0）；IPv6 流量 -- 未知流量（9）。
ISP_8_WAN_PORT=0
ISP_8_WAN_PORT_V6=9

# 台湾地区运营商 IPv4/IPv6 目标网段客户端流量（网段数据文件：tw_cidr.txt/tw_ipv6.txt）
# 0 -- 第一 WAN 口；1 -- 第二 WAN 口；···；7 -- 第八 WAN 口；8 -- 负载均衡；9 -- 未知流量（mwan3 中设置处理）；取值范围：0 ~ 9
# 缺省：IPv4 流量 -- 第二 WAN 口（0）；IPv6 流量 -- 未知流量（9）。
ISP_9_WAN_PORT=0
ISP_9_WAN_PORT_V6=9

# 路由器本机内部应用访问外部 IPv4/IPv6 流量出口
# 0 -- 第一 WAN 口；1 -- 第二 WAN 口；···；7 -- 第八 WAN 口；8 -- 系统分配（按主路由表中缺省设置自动分配出口）；取值范围：0 ~ 8
# 缺省：IPv4 流量 -- 系统分配（8）；IPv6 流量 -- 系统分配（8）。
HOST_WAN_PORT=8
HOST_V6_WAN_PORT=8

# 定时更新 ISP 网络运营商 CIDR 网段数据时间参数定义
# 建议在当天 1:30 后执行定时更新。
# 缺省为每隔 3 天，小时数和分钟数由系统指定。
INTERVAL_DAY=3  # 间隔天数（1 ~ 31）：取值 3 表示每隔 3 天；取值 0 表示停用定时更新。
TIMER_HOUR=x    # 时间小时数（0 ~ 23，x 表示由系统指定）；取值 3 表示更新当天的凌晨 3 点。
TIMER_MIN=x     # 时间分钟数（0 ~ 59，x 表示由系统指定）；取值 18 表示更新当天的凌晨 3 点 18 分。
# 网段数据变更不很频繁，更新间隔时间不要太密集，有助于降低远程下载服务器的负荷压力。
# 脚本运行期间，修改定时设置、路由器重启，或手工停止脚本运行后再次重启，会导致定时更新时间重新开始计数。

# 定时更新 ISP 网络运营商CIDR网段数据失败后自动重试次数
# 0 -- 不重试；> 0 -- 重试次数；取值范围：0 ~ 99
# 缺省为重试 5 次。
RETRY_NUM=5
# 若自动重试后经常下载失败，建议自行前往 https://ispip.clang.cn/ 网站手工下载获取与上述 10 个网络运营商网
# 段数据文件同名的最新 CIDR 网段数据，下载后直接粘贴覆盖 /etc/lzrules/data/ 目录内同名数据文件，重启脚本即
# 刻生效。

# 完成出口设定后，需将 WAN 口的网段数据集合名称（例如：ISPIP_SET_0）填入「MultiWAN 管理器」内相应 WAN 口策略规
# 则条目中的「IP 配置」字段内，形成绑定关系，即可最终通过 OpenWrt 内的 mwan3 软件完成多 WAN 口流量的策略路由。脚本
# 的主要作用就是为 mwan3 生成可供其多个 WAN 口通道选择使用的目标流量网段地址数据集合，从而实现更复杂的业务策略。

# WAN 口国内 IPv4 网段数据集合名称
# 从上往下按 mwan3 设置中第一 WAN 口、第二 WAN 口至第八 WAN 口的顺序排列，每个 WAN 口一个，可最多对应八个 WAN 口的使用。
ISPIP_SET_0="ISPIP_SET_0"
ISPIP_SET_1="ISPIP_SET_1"
ISPIP_SET_2="ISPIP_SET_2"
ISPIP_SET_3="ISPIP_SET_3"
ISPIP_SET_4="ISPIP_SET_4"
ISPIP_SET_5="ISPIP_SET_5"
ISPIP_SET_6="ISPIP_SET_6"
ISPIP_SET_7="ISPIP_SET_7"

# WAN 口国内 IPv6 网段数据集合名称
# 从上往下按 mwan3 设置中第一 WAN 口、第二 WAN 口至第八 WAN 口的顺序排列，每个 WAN 口一个，可最多对应八个 WAN 口的使用。
ISPIP_V6_SET_0="ISPIP_V6_SET_0"
ISPIP_V6_SET_1="ISPIP_V6_SET_1"
ISPIP_V6_SET_2="ISPIP_V6_SET_2"
ISPIP_V6_SET_3="ISPIP_V6_SET_3"
ISPIP_V6_SET_4="ISPIP_V6_SET_4"
ISPIP_V6_SET_5="ISPIP_V6_SET_5"
ISPIP_V6_SET_6="ISPIP_V6_SET_6"
ISPIP_V6_SET_7="ISPIP_V6_SET_7"

# 多 WAN 口 IPv4 流量负载均衡数据集合名称
ISPIP_SET_B="ISPIP_SET_B"

# 多 WAN 口 IPv6 流量负载均衡数据集合名称
ISPIP_V6_SET_B="ISPIP_V6_SET_B"

# 用户自定义 IPv4 目标访问网址/网段数据集合列表文件（custom_ipsets_lst.txt）
# 0 -- 启用；1 -- 停用；取值范围：0 ~ 1
# 缺省为停用（1）。
CUSTOM_IPSETS=1
# 该列表文件位于项目路径内的 data 目录内，文本文件，名称和路径不可更改。
# 每一行可定义一个网址/网段数据集合，可定义多条，数量不限。数据集合可在 mwan3 的 WAN 口流量策略规则设置中使用。
# 格式：
# 数据集合名称="全路径 IPv4 网址/网段数据文件名"
# 注意：
# 数据集合名称在整个路由器系统中具有唯一性，不能重复，否则会创建失败或影响系统中的其他代码运行；等号前后不能
# 有空格；输入字符为英文半角，且符合 Linux 变量名称、路径命名、文件命名的规则；全路径文件名要用英文半角双引号
# 括起来。
# 例如：
# MY_IPSET_0="/mypath/my_ip_address_list_0.txt" # 我的第一个 IPv4 网址/网段数据集合
# MY_IPSET_1="/mypath/my_ip_address_list_1.txt"
# 条目起始处加 # 符号，可忽略该条定义；在每条定义后面加空格，再添加 # 符号，后面可填写该条目的备注。
# 网址/网段数据文件由用户自己编制和命名，内容格式可参考 data 目录内的运营是网段数据文件，每行为一个 IPv4 格式的
# IP 地址或 CIDR 网段，不能是域名形式的网址，可填写多个条目，数量不限。
# 定义完数据集合列表文件和网址/网段数据文件后，需前往 OpenWrt「网络 - MultiWAN 管理器 - 规则」界面内，为每个网址/
# 网段数据集合按规则优先级添加和设置单独的出口规则，实现所需的流量出口策略。

# 用户自定义 IPv6 目标访问网址/网段数据集合列表文件（custom_ipv6_ipsets_lst.txt）
# 0 -- 启用；1 -- 停用；取值范围：0 ~ 1
# 缺省为停用（1）。
CUSTOM_V6_IPSETS=1
# 该列表文件位于项目路径内的 data 目录内，文本文件，名称和路径不可更改。
# 每一行可定义一个网址/网段数据集合，可定义多条，数量不限。数据集合可在 mwan3 的 WAN 口流量策略规则设置中使用。
# 格式：
# 数据集合名称="全路径 IPv6 网址/网段数据文件名"
# 注意：
# 数据集合名称在整个路由器系统中具有唯一性，不能重复，否则会创建失败或影响系统中的其他代码运行；等号前后不能
# 有空格；输入字符为英文半角，且符合 Linux 变量名称、路径命名、文件命名的规则；全路径文件名要用英文半角双引号
# 括起来。
# 例如：
# MY_V6_IPSET_0="/mypath/my_ipv6_address_list_0.txt" # 我的第一个 IPv6 网址/网段数据集合
# MY_V6_IPSET_1="/mypath/my_ipv6_address_list_1.txt"
# 条目起始处加 # 符号，可忽略该条定义；在每条定义后面加空格，再添加 # 符号，后面可填写该条目的备注。
# 网址/网段数据文件由用户自己编制和命名，内容格式可参考 data 目录内的运营是网段数据文件，每行为一个 IPv6 格式的
# IP 地址或网段，不能是域名形式的网址，可填写多个条目，数量不限。
# 定义完数据集合列表文件和网址/网段数据文件后，需前往 OpenWrt「网络 - MultiWAN 管理器 - 规则」界面内，为每个网址/
# 网段数据集合按规则优先级添加和设置单独的出口规则，实现所需的流量出口策略。

# 用户自定义目标访问域名 IPv4 数据集合列表文件（dname_ipsets_lst.txt）
# 0 -- 启用；1 -- 停用；取值范围：0 ~ 1
# 缺省为停用（1）。
DNAME_IPSETS=1
# 该功能仅适用于 OpenWrt 防火墙 FW3 版本的固件。
# 该列表文件位于项目路径内的 data 目录内，文本文件，名称和路径不可更改。
# 每一行可定义一个域名数据集合，可定义多个，数量不限。数据集合可在 mwan3 的 WAN 口流量策略规则设置中使用。
# 格式：
# 数据集合名称
# 注意：
# 数据集合名称在整个路由器系统中具有唯一性，不能重复，否则会创建失败或影响系统中的其他代码运行；输入字符为英
# 文半角，且符合 Linux 变量名称命名的规则。
# 例如：
# MY_DOMAIN_NAME_IPSET_0 # 我的第一个域名数据集合
# MY_DOMAIN_NAME_IPSET_1
# 条目起始处加 # 符号，可忽略该条定义；在每条定义后面加空格，再添加 # 符号，后面可填写该条目备注。
# 此处仅作为全局变量在系统运行空间中定义和初始化域名数据集合，对域名数据集合进行生命周期管理。
# 定义完成后请前往 OpenWrt 的「网络 - DHCP/DNS - IP集」选项卡中，给数据集合关联所需域名，每个数据集合可包含多个域名，
# 最后在 mwan3 的 WAN 口流量策略规则中为每个域名数据集合按规则优先级添加和设置单独的出口规则，实现按所访问的域名
# 分配流量出口的策略。


# ---------------------全局变量---------------------

# WAN口最大支持数量
# 每个 IPv4 WAN 口对应一个国内网段数据集合
MAX_WAN_PORT="8"

# 国内 ISP 网络运营商 CIDR 网段数据文件总数
ISP_TOTAL="10"

# 国内 ISP 网络运营商 IPv4 CIDR 网段数据文件名
ISP_DATA_0="chinatelecom_cidr.txt"
ISP_DATA_1="unicom_cnc_cidr.txt"
ISP_DATA_2="cmcc_cidr.txt"
ISP_DATA_3="crtc_cidr.txt"
ISP_DATA_4="cernet_cidr.txt"
ISP_DATA_5="gwbn_cidr.txt"
ISP_DATA_6="othernet_cidr.txt"
ISP_DATA_7="hk_cidr.txt"
ISP_DATA_8="mo_cidr.txt"
ISP_DATA_9="tw_cidr.txt"

# 国内 ISP 网络运营商 IPv6 网段数据文件名
ISP_V6_DATA_0="chinatelecom_ipv6.txt"
ISP_V6_DATA_1="unicom_cnc_ipv6.txt"
ISP_V6_DATA_2="cmcc_ipv6.txt"
ISP_V6_DATA_3="crtc_ipv6.txt"
ISP_V6_DATA_4="cernet_ipv6.txt"
ISP_V6_DATA_5="gwbn_ipv6.txt"
ISP_V6_DATA_6="othernet_ipv6.txt"
ISP_V6_DATA_7="hk_ipv6.txt"
ISP_V6_DATA_8="mo_ipv6.txt"
ISP_V6_DATA_9="tw_ipv6.txt"

# 国内 ISP 网络运营商名称
ISP_NAME_0="CTCC       "
ISP_NAME_1="CUCC/CNC   "
ISP_NAME_2="CMCC       "
ISP_NAME_3="CRTC       "
ISP_NAME_4="CERNET     "
ISP_NAME_5="GWBN       "
ISP_NAME_6="OTHER      "
ISP_NAME_7="HONGKONG   "
ISP_NAME_8="MACAO      "
ISP_NAME_9="TAIWAN     "

# 国内 ISP 网络运营商名称
ISP_V6_NAME_0="V6_CTCC    "
ISP_V6_NAME_1="V6_CUCC/CNC"
ISP_V6_NAME_2="V6_CMCC    "
ISP_V6_NAME_3="V6_CRTC    "
ISP_V6_NAME_4="V6_CERNET  "
ISP_V6_NAME_5="V6_GWBN    "
ISP_V6_NAME_6="V6_OTHER   "
ISP_V6_NAME_7="V6_HONGKONG"
ISP_V6_NAME_8="V6_MACAO   "
ISP_V6_NAME_9="V6_TAIWAN  "

# WAN 端口设备属性列表
WAN_DEV_PROPERTY_LIST="${WAN_DEV_PROPERTY_LIST:-""}"

# IPv4 WAN 端口设备列表
WAN_DEV_LIST="${WAN_DEV_LIST:-""}"

# IPv6 WAN 端口设备列表
WAN_V6_DEV_LIST="${WAN_V6_DEV_LIST:-""}"

# IPv4 主路由表网卡接口设备列表
RT_DEV_LIST="${RT_DEV_LIST:-""}"

# IPv6 主路由表网卡接口设备列表
RT_V6_DEV_LIST="${RT_V6_DEV_LIST:-""}"

# 可用 IPv4 WAN 口数量
WAN_AVAL_NUM="0"

# 可用 IPv6 WAN 口数量
WAN_V6_AVAL_NUM="0"

# 用户自定义 IPv4 目标访问网址/网段数据集合列表
CUSTOM_IPSETS_LST=""

# 用户自定义 IPv6 目标访问网址/网段数据集合列表
CUSTOM_V6_IPSETS_LST=""

# 用户自定义目标访问域名数据集合列表
DNAME_IPSETS_LST=""

# 版本号
LZ_VERSION=v2.2.0

# 项目标识
PROJECT_ID="lzrules"

# 项目文件名
PROJECT_FILENAME="${PROJECT_ID}.sh"

# 项目文件路径
PATH_LZ="${0%/*}"
[ "${PATH_LZ:0:1}" != '/' ] && PATH_LZ="$( pwd )${PATH_LZ#*.}"
PATH_DATA="${PATH_LZ}/data"
PATH_TMP="${PATH_LZ}/tmp"

# 系统启动引导配置文件名
BOOT_START_FILENAME="/etc/rc.local"

# 系统计划任务配置文件名
CRONTABS_ROOT_FILENAME="/etc/crontabs/root"

# 主机网络配置文件名
HOST_NETWORK_FILENAME="/etc/config/network"

# mwan3 配置文件名
MWAN3_FILENAME="/etc/config/mwan3"

# mwan3 事件通告文件名
MWAN3_NOTIFY_FILENAME="/etc/mwan3.user"

# 主机 dhcp 配置文件名
HOST_DHCP_FILENAME="/etc/config/dhcp"

# 更新 ISP 网络运营商 CID R网段数据文件临时下载目录
PATH_TMP_DATA="${PATH_TMP}/download"

# ISP 网络运营商 CIDR 网段数据文件下载站点URL
UPDATE_ISPIP_DATA_DOWNLOAD_URL="https://ispip.clang.cn"

# ISP 网络运营商 CIDR 网段数据文件 URL 列表文件名
ISPIP_FILE_URL_LIST="ispip_file_url.lst"

# 公网出口 IPv4 地址查询网站域名
PIPDN="whatismyip.akamai.com"

# 公网出口 IPv4 地址查询备用网站域名
PIPDNX="checkip.amazonaws.com"

# 用户自定义 IPv4 网址/网段数据集合列表文件名
CUSTOM_IPSETS_LST_FILENAME="${PATH_DATA}/custom_ipsets_lst.txt"

# 用户自定义 IPv6 网址/网段数据集合列表文件名
CUSTOM_V6_IPSETS_LST_FILENAME="${PATH_DATA}/custom_ipv6_ipsets_lst.txt"

# 用户自定义目标访问域名数据集合列表文件名
DNAME_IPSETS_LST_FILENAME="${PATH_DATA}/dname_ipsets_lst.txt"

# 用户自定义数据集合运行列表临时文件名
CUSTOM_IPSETS_TMP_LST_FILENAME="${PATH_TMP}/custom_ipsets_tmp.lst"

# IPv4 地址正则表达式
regex_v4='((25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9])[\.]){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9])([\/]([1-9]|[1-2][0-9]|3[0-2]))?'

# IPv6 地址正则表达式
regex_v6='(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:([0-9a-fA-F]{1,4})|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{1,4}){0,4}%[0-9a-zA-Z]+|::(ffff(:0{1,4})?:)?REGEX_IPV4|([0-9a-fA-F]{1,4}:){1,4}:REGEX_IPV4)([\/]([1-9]|([1-9]|1[0-1])[0-9]|12[0-8]))?'
regex_v6="$( echo "${regex_v6}" | sed "s/REGEX_IPV4/${regex_v4%"([\/]("*}/g" )"

# 用户自定义策略规则路优先级
CUSTOM_PRIO="500"

# 脚本操作命令
HAMMER="$( echo "${1}" | tr '[:A-Z:]' '[:a-z:]' )"
UPDATE="update"
UNLOAD="unload"
PARAM_TOTAL="${#}"

MY_LINE="[$$]: -----------------------------------------------"


# ---------------------函数定义---------------------

lzdate() { date +"%F %T"; }

check_suport_evn() {
    local retval="0"
    while true
    do
        if [ ! -f "${HOST_NETWORK_FILENAME}" ]; then
            echo "$(lzdate)" [$$]: Profile "${HOST_NETWORK_FILENAME}" may be corrupt or missing.
            logger -p 1 "[$$]: Profile ${HOST_NETWORK_FILENAME} may be corrupt or missing."
            retval="1"
        fi
        if [ ! -f "${HOST_DHCP_FILENAME}" ]; then
            echo "$(lzdate)" [$$]: Profile "${HOST_DHCP_FILENAME}" may be corrupt or missing.
            logger -p 1 "[$$]: Profile ${HOST_DHCP_FILENAME} may be corrupt or missing."
            retval="1"
        fi
        if ! which opkg > /dev/null 2>&1; then
            echo "$(lzdate)" [$$]: No opkg, this script cannot be run.
            logger -p 1 "[$$]: No opkg."
            retval="1"
            break
        fi
        if [ -z "$( opkg list-installed "mwan3" 2> /dev/null )" ] || ! which mwan3 > /dev/null 2>&1 || [ ! -f "${MWAN3_FILENAME}" ]; then
            echo "$(lzdate)" [$$]: Package mwan3 is not installed or corrupt.
            logger -p 1 "[$$]: Package mwan3 is not installed or corrupt."
            retval="1"
        fi
        if [ -z "$( opkg list-installed "luci-app-mwan3" 2> /dev/null )" ]; then
            echo "$(lzdate)" [$$]: Package luci-app-mwan3 is not installed or corrupt.
            logger -p 1 "[$$]: Package luci-app-mwan3 is not installed or corrupt."
            retval="1"
        fi
        if [ -z "$( opkg list-installed "wget-ssl" 2> /dev/null )" ] || ! which wget > /dev/null 2>&1; then
            echo "$(lzdate)" [$$]: Package wget-ssl is not installed or corrupt.
            logger -p 1 "[$$]: Package wget-ssl is not installed or corrupt."
            retval="1"
        fi
        if ! which ipset > /dev/null 2>&1; then
            echo "$(lzdate)" [$$]: Package ipset is not installed.
            logger -p 1 "[$$]: Package ipset is not installed."
            retval="1"
        fi
        if [ -z "$( opkg list-installed "dnsmasq-full" 2> /dev/null )" ] || ! which dnsmasq > /dev/null 2>&1; then
            echo "$(lzdate)" [$$]: Package dnsmasq-full is not installed or corrupt.
            logger -p 1 "[$$]: Package dnsmasq-full is not installed or corrupt."
            retval="1"
        fi
        if awk -F "\'" '$1 == "DISTRIB_RELEASE=" {print $2}' "/etc/openwrt_release" 2> /dev/null | grep -qE '^22[\.][0]*3[\.]' \
            || awk -F "\"" '$1 == ""VERSION=" {print $2}' "/etc/os-release" 2> /dev/null | grep -qE '^22[\.][0]*3[\.]'; then
            if [ -z "$( opkg list-installed "iptables-nft" 2> /dev/null )" ] || ! which iptables-nft > /dev/null 2>&1; then
                echo "$(lzdate)" [$$]: Package iptables-nft is not installed or corrupt.
                logger -p 1 "[$$]: Package iptables-nft is not installed or corrupt."
                retval="1"
            fi
            if [ -z "$( opkg list-installed "ip6tables-nft" 2> /dev/null )" ] || ! which ip6tables-nft > /dev/null 2>&1; then
                echo "$(lzdate)" [$$]: Package ip6tables-nft is not installed or corrupt.
                logger -p 1 "[$$]: Package ip6tables-nft is not installed or corrupt."
                retval="1"
            fi
        fi
        break
    done
    if [ "${retval}" != "0" ]; then
        echo "$(lzdate)" [$$]: This script cannot be run.
        logger -p 1 "[$$]: This script cannot be run."
    fi
    return "${retval}"
}

cleaning_user_data() {
    ! echo "${ISP_0_WAN_PORT}" | grep -q '^[0-9]$' && ISP_0_WAN_PORT=0
    ! echo "${ISP_1_WAN_PORT}" | grep -q '^[0-9]$' && ISP_1_WAN_PORT=0
    ! echo "${ISP_2_WAN_PORT}" | grep -q '^[0-9]$' && ISP_2_WAN_PORT=1
    ! echo "${ISP_3_WAN_PORT}" | grep -q '^[0-9]$' && ISP_3_WAN_PORT=1
    ! echo "${ISP_4_WAN_PORT}" | grep -q '^[0-9]$' && ISP_4_WAN_PORT=1
    ! echo "${ISP_5_WAN_PORT}" | grep -q '^[0-9]$' && ISP_5_WAN_PORT=1
    ! echo "${ISP_6_WAN_PORT}" | grep -q '^[0-9]$' && ISP_6_WAN_PORT=0
    ! echo "${ISP_7_WAN_PORT}" | grep -q '^[0-9]$' && ISP_7_WAN_PORT=0
    ! echo "${ISP_8_WAN_PORT}" | grep -q '^[0-9]$' && ISP_8_WAN_PORT=0
    ! echo "${ISP_9_WAN_PORT}" | grep -q '^[0-9]$' && ISP_9_WAN_PORT=0
    ! echo "${HOST_WAN_PORT}" | grep -q '^[0-8]$' && HOST_WAN_PORT=8
    ! echo "${HOST_V6_WAN_PORT}" | grep -q '^[0-8]$' && HOST_V6_WAN_PORT=8
    local index="0"
    until [ "${index}" -ge "${ISP_TOTAL}" ]
    do
        ! eval echo "\${ISP_${index}_WAN_PORT_V6}" | grep -q '^[0-9]$' && eval "ISP_${index}_WAN_PORT_V6=9"
        index="$(( index + 1 ))"
    done
    ! echo "${INTERVAL_DAY}" | grep -qE '^[0-9]$|^[1-2][0-9]$|^[3][0-1]$' && INTERVAL_DAY=3
    ! echo "${TIMER_HOUR}" | grep -qE '^[0-9]$|^[1][0-9]$|^[2][0-3]$|^[xX]$' && TIMER_HOUR=x
    [ "${TIMER_HOUR}" = "X" ] && TIMER_HOUR=x
    ! echo "${TIMER_MIN}" | grep -qE '^[0-9]$|^[1-5][0-9]$|^[xX]$' && TIMER_MIN=x
    [ "${TIMER_MIN}" = "X" ] && TIMER_MIN=x
    ! echo "${RETRY_NUM}" | grep -qE '^[0-9]$|^[1-9][0-9]$' && RETRY_NUM=5
    ! echo "${CUSTOM_IPSETS}" | grep -q '^[0-1]$' && CUSTOM_IPSETS=1
    ! echo "${CUSTOM_V6_IPSETS}" | grep -q '^[0-1]$' && CUSTOM_V6_IPSETS=1
    ! echo "${DNAME_IPSETS}" | grep -q '^[0-1]$' && DNAME_IPSETS=1
}

ifstatus_dev() {
    local l3="${2}"
    if [ "${l3}" != "l3" ]; then
        l3="device"
    else
        l3="l3_device"
    fi
    ifstatus "${1}" 2> /dev/null \
        | awk -v count="0" '$1 == "\"""'"${l3}"'""\":" {
            count++;
            ifn = $2;
            gsub(/[[:space:]\"\,]/, "", ifn);
            if (ifn != "")
                print ifn;
            else
                print "Error";
        } END{
            if (count == "0")
                print "Error";
        }'
}

get_wan_dev_list() {
    RT_DEV_LIST="$( ip route show 2> /dev/null | awk '/default/ {print $5}' | awk 'NF == 1 && !i[$1]++ {print $1}' )"
    RT_V6_DEV_LIST="$( ip -6 route show 2> /dev/null | awk '/default/ {print $7}' | awk 'NF == 1 && !i[$1]++ {print $1}' )"
    local wan_list=""  wan_v6_list="" ifn="" wan="" num="0"
    local dev_list="$( eval "$( eval "$( uci show network 2> /dev/null \
        | awk -F '=' '$2 == "interface" {
            ifn = $1;
            gsub(/^.*[\.]/, "", ifn);
            print "echo "ifn" \"\$( uci get network."ifn".proto 2> /dev/nul )\" \"\$( uci get network."ifn".device 2> /dev/nul )\" \"\$( uci get network."ifn".ifname 2> /dev/nul )\"";
        }' )" \
        | awk 'NF >= 3 && $3 !~ /^(lo|br-lan)$/ && $3 != "@"$1 && !i[$1]++ {
            print "echo "$1" "$2" "$3" \"\$( ifstatus_dev "$1" "l3" )\" \"\$( ifstatus_dev "$1" )\"";
        }' )" )"
    local MAX_NUM="$( echo "${dev_list}" | wc -l )" count="0" \
        xcount="$( echo "${dev_list}" | awk -v count="0" '$5 == "Error" {count++;} END{print count;}' )" ycount="0"
    while [ "${xcount}" -gt "0" ]; do
        for ifn in $( echo "${dev_list}" | awk 'NF == 5 && $3 ~ /^@/ && $5 == "Error" {wan = $3; sub(/^@/, "", wan); print $1"^"wan;}' )
        do
            wan="$( echo "${dev_list}" | awk '$1 == "'"${ifn##*^}"'" {print $5}' )"
            if [ "${wan}" != "Error" ]; then
                if [ -z "${wan}" ]; then
                    dev_list="$( echo "${dev_list}" | awk 'NF == 5 && $1 != "'"${ifn%%^*}"'"' )"
                else
                    dev_list="$( echo "${dev_list}" | awk 'NF == 5 {
                        if ($1 == "'"${ifn%%^*}"'" && $5 == "Error")
                            print $1,$2,$3,$4,"'"${wan}"'";
                        else
                            print $0;
                        }' )"
                fi
            fi
        done
        xcount="$( echo "${dev_list}" | awk -v count="0" '$5 == "Error" {count++;} END{print count;}' )"
        if [ "${xcount}" != "${ycount}" ]; then
            ycount="${xcount}"
            count="0"
        else
            count="$(( count + 1 ))"
            [ "${count}" -ge "${MAX_NUM}" ] && break
        fi
    done
    dev_list="$( echo "${dev_list}" | awk 'NF == 5 && $5 != "Error"' )" 
    WAN_DEV_PROPERTY_LIST="${dev_list}"
    dev_list="$( echo "${dev_list}" | awk 'NF == 5 {wan = $1; if ($4 == "Error") wan = wan"->?!"; print wan,$2,$3,$4,$5;}' )"
    wan_list="$( echo "${dev_list}" | awk -v count=0 'NF == 5 && $2 != "dhcpv6" && !i[$5]++ {print $1,$5; count++; if (count >= "'"${MAX_WAN_PORT}"'") exit;}' )"
    for ifn in $( echo "${wan_list}" | awk 'NF == 2 {print $2}' )
    do
        wan="$( echo "${dev_list}" | awk 'NF == 5 && $2 == "pppoe" && $4 != "Error" && $5 == "'"${ifn}"'" {print $1; exit;}' )"
        [ -z "${wan}" ] && wan="$( echo "${dev_list}" | awk 'NF == 5 && $2 == "ppp" && $4 != "Error" && $5 == "'"${ifn}"'" {print $1; exit;}' )"
        [ -z "${wan}" ] && wan="$( echo "${dev_list}" | awk 'NF == 5 && $2 == "dhcp" && $4 != "Error" && $5 == "'"${ifn}"'" {print $1; exit;}' )"
        [ -z "${wan}" ] && wan="$( echo "${dev_list}" | awk 'NF == 5 && $2 == "static" && $4 != "Error" && $5 == "'"${ifn}"'" {print $1; exit;}' )"
        [ -z "${wan}" ] && wan="$( echo "${dev_list}" | awk 'NF == 5 && $2 == "none" && $4 != "Error" && $5 == "'"${ifn}"'" {print $1; exit;}' )"
        if [ -z "${wan}" ]; then
            wan="$( echo "${dev_list}" | awk 'NF == 5 && $2 == "pppoe" && $5 == "'"${ifn}"'" {print $1; exit;}' )"
            [ -z "${wan}" ] && wan="$( echo "${dev_list}" | awk 'NF == 5 && $2 == "ppp" && $5 == "'"${ifn}"'" {print $1; exit;}' )"
            [ -z "${wan}" ] && wan="$( echo "${dev_list}" | awk 'NF == 5 && $2 == "dhcp" && $5 == "'"${ifn}"'" {print $1; exit;}' )"
            [ -z "${wan}" ] && wan="$( echo "${dev_list}" | awk 'NF == 5 && $2 == "static" && $5 == "'"${ifn}"'" {print $1; exit;}' )"
            [ -z "${wan}" ] && wan="$( echo "${dev_list}" | awk 'NF == 5 && $2 == "none" && $5 == "'"${ifn}"'" {print $1; exit;}' )"
        fi
        [ -n "${wan}" ] && wan_list="$( echo "${wan_list}" | awk 'NF == 2 {
                if ($2 == "'"${ifn}"'")
                    print "'"${wan}"'",$2;
                else
                    print $0;
            }' )"
    done
    wan_v6_list="$( echo "${dev_list}" | awk -v count=0 'NF == 5 && $2 == "dhcpv6" && !i[$5]++ {print $1,$5; count++; if (count >= "'"${MAX_WAN_PORT}"'") exit;}' )"
    for ifn in $( echo "${wan_v6_list}" | awk '{print $2}' )
    do
        wan="$( echo "${dev_list}" | awk 'NF == 5 && $2 == "dhcpv6" && $4 != "Error" $5 == "'"${ifn}"'" {print $1; exit;}' )"
        [ -z "${wan}" ] && wan="$( echo "${dev_list}" | awk 'NF == 5 && $2 == "dhcpv6" && $5 == "'"${ifn}"'" {print $1; exit;}' )"
        [ -n "${wan}" ] && wan_v6_list="$( echo "${wan_v6_list}" | awk 'NF == 2 {
                if ($2 == "'"${ifn}"'")
                    print "'"${wan}"'",$2;
                else
                    print $0;
            }' )"
    done
    dev_list="$( echo "${dev_list}" | awk -v count=0 'NF > 0 && !i[$5]++ {print $5; count++; if (count >= "'"${MAX_WAN_PORT}"'") exit;}' )"
    num="$( echo "${dev_list}" | wc -l )"
    until [ "${num}" -ge "${MAX_WAN_PORT}" ]
    do
        num="$(( num + 1 ))"
        dev_list="$( echo "${dev_list}" | sed -e "\$a eth${num}X" -e '/^[[:space:]]*$/d' )"
    done
    WAN_DEV_LIST="$( echo "${dev_list}" | awk -v count=0 'NF > 0 {print "wan"count"X",$1; count++;}' )"
    WAN_V6_DEV_LIST="$( echo "${dev_list}" | awk -v count=0 'NF > 0 {print "wan"count"v6X",$1; count++;}' )"
    num="0"
    for ifn in $( echo "${wan_list}" | awk '{print $2}' )
    do
        WAN_DEV_LIST="$( echo "${WAN_DEV_LIST}" | awk -v str="$( echo "${wan_list}" \
            | awk '$2 == "'"${ifn}"'" {print $1; exit;}' )" '{
                if (str != "" && $2 == "'"${ifn}"'")
                    print str,$2;
                else
                    print $0;
            }' )"
        num="$(( num + 1 ))"
    done
    WAN_AVAL_NUM="${num}"
    num="0"
    for ifn in $( echo "${wan_v6_list}" | awk '{print $2}' )
    do
        WAN_V6_DEV_LIST="$( echo "${WAN_V6_DEV_LIST}" | awk -v str="$( echo "${wan_v6_list}" \
            | awk '$2 == "'"${ifn}"'" {print $1; exit;}' )" '{
                if (str != "" && $2 == "'"${ifn}"'")
                    print str,$2;
                else
                    print $0;
            }' )"
        num="$(( num + 1 ))"
    done
    WAN_V6_AVAL_NUM="${num}"
}

get_wan_property_dev() {
    local wan="${1}"
    [ -n "${WAN_DEV_PROPERTY_LIST}" ] && wan="$( echo "${WAN_DEV_PROPERTY_LIST}" | awk '$1 == "'"${wan}"'" {print $5; exit}' )"
    [ -z "${wan}" ] && wan="${1}"
    echo "${wan}"
}

get_wan_if() {
    local wan="${1}"
    [ -n "${WAN_DEV_LIST}" ] && wan="$( echo "${WAN_DEV_LIST}" | awk '$2 == "'"${wan}"'" {print $1; exit}' )"
    [ -z "${wan}" ] && wan="${1}"
    echo "${wan}"
}

get_wan_dev() {
    local wan="${1}"
    [ -n "${WAN_DEV_LIST}" ] && wan="$( echo "${WAN_DEV_LIST}" | awk '$1 == "'"${wan}"'" {print $2; exit}' )"
    [ -z "${wan}" ] && wan="${1}"
    echo "${wan}"
}

get_wan_if_v6() {
    local wan="${1}"
    [ -n "${WAN_V6_DEV_LIST}" ] && wan="$( echo "${WAN_V6_DEV_LIST}" | awk '$2 == "'"${wan}"'" {print $1; exit}' )"
    [ -z "${wan}" ] && wan="${1}"
    echo "${wan}"
}

get_wan_name() {
    local index="${1}" wan="" 
    index="$(( index + 1 ))"
    [ -n "${WAN_DEV_LIST}" ] && wan="$( echo "${WAN_DEV_LIST}" | awk 'NR == ("'"${index}"'" + 0) {print $1}' )"
    echo "${wan}"
}

get_wan_name_v6() {
    local index="${1}" wan="" 
    index="$(( index + 1 ))"
    [ -n "${WAN_V6_DEV_LIST}" ] && wan="$( echo "${WAN_V6_DEV_LIST}" | awk 'NR == ("'"${index}"'" + 0) {print $1}' )"
    echo "${wan}"
}

get_main_rt_default_dev() {
    [ "${1}" != "4" ] && [ "${1}" != "6" ] && { echo ""; return; }
    ip "-${1}" route show 2> /dev/null \
        | awk '/default/ {
            metric = 0;
            for (i = 1; i <= NF; i++) {
                if ($i == "metric" && $(i + 1) ~ /^[0-9]+$/) {
                    metric = $(i + 1);
                    break;
                }
            }
            print metric,$("'"${1}"'" + 1) | "sort -t \" \" -k 1 -n";
        }' \
        | awk 'NR == 1 {print $2; exit;}'
}

check_dev_sub_rt_id() {
    ip "-${1}" route show table "${3}" 2> /dev/null \
        | awk '/default/ {
            metric = 0;
            for (i = 1; i <= NF; i++) {
                if ($i == "metric" && $(i + 1) ~ /^[0-9]+$/) {
                    metric = $(i + 1);
                    break;
                }
            }
            print metric,$5 | "sort -t \" \" -k 1 -n";
        }' \
        | awk 'NR == 1 && $2 == "'"${2}"'" {print "'"${3}"'"; exit;}'
}

get_sub_rt_id() {
    local retVal="" tableID="1"
    if { [ "${1}" != "4" ] && [ "${1}" != "6" ]; } || [ -z "${2}" ]; then
        echo "${retVal}"
        return
    fi
    retVal="$( ip "-${1}" rule show 2> /dev/null \
        | awk 'NF >= 7 && $1 ~ /^[0-9]+[:]$/ && $2" "$3" "$4 == "from all iif" && $5 == "'"${2}"'" && $6 == "lookup" {print $7;}' )"
    for retVal in ${retVal}
    do
        retVal="$( check_dev_sub_rt_id "${1}" "${2}" "${retVal}" )"
        [ -n "${retVal}" ] && break
    done
    while [ -z "${retVal}" ] && [ "${tableID}" -le "$(( WAN_AVAL_NUM + WAN_V6_AVAL_NUM ))" ]
    do
        retVal="$( check_dev_sub_rt_id "${1}" "${2}" "${tableID}" )"
        tableID="$(( tableID + 1 ))"
    done
    echo "${retVal}"
}

add_wan_address_rule() {
    local tableID="" ifn="" count="0"
    ifn="$( ip route show 2> /dev/null | awk '/default/ {print $5}' | awk 'NF == 1 && !i[$1]++ {print $1}' )"
    for ifn in ${ifn}
    do
        tableID="$( get_sub_rt_id "4" "${ifn}" )"
        [ -z "${tableID}" ] && continue
        eval "$( ip -4 -o address show dev "${ifn}" 2> /dev/null | awk 'NF != 0 && $4 ~ "'"^${regex_v4}$"'" {
            ifa=$4;
            gsub(/\/.*$/, "", ifa);
            print "ip rule add from "ifa" table ""'"${tableID}"'"" prio ""'"${CUSTOM_PRIO}"'"" > /dev/null 2>&1; count=\"$(( count + 1 ))\";";
        }' )"
    done
    [ "${count}" != "0" ] && ip route flush cache > /dev/null 2>&1
    tableID="" ifn="" count="0"
    ifn="$( ip -6 route show 2> /dev/null | awk '/default/ {print $7}' | awk 'NF == 1 && !i[$1]++ {print $1}' )"
    for ifn in ${ifn}
    do
        tableID="$( get_sub_rt_id "6" "${ifn}" )"
        [ -z "${tableID}" ] && continue
        eval "$( ip -6 -o address show dev "${ifn}" 2> /dev/null \
            | awk 'NF != 0 && $4 ~ "'"^${regex_v6}$"'" && $4 !~ /^[fF][eE][89abAB][0-9a-fA-F]:/ {
            ifa=$4;
            gsub(/\/.*$/, "", ifa);
            print "ip -6 rule add from "ifa" table ""'"${tableID}"'"" prio ""'"${CUSTOM_PRIO}"'"" > /dev/null 2>&1; count=\"$(( count + 1 ))\";";
        }' )"
    done
    [ "${count}" != "0" ] && ip -6 route flush cache > /dev/null 2>&1
}

add_host_port_rule() {
    local ifn="" port="" str="System" tableID="" strbuf=""
    while true
    do
        [ "${HOST_WAN_PORT}" -ge "${MAX_WAN_PORT}" ] && break
        ifn="$( echo "${WAN_DEV_LIST}" | awk 'NR == (1 + "'"${HOST_WAN_PORT}"'") && $1 !~ /X$/ && $2 !~ /X$/ {print $1; exit;}' )"
        [ -z "${ifn}" ] && break
        eval "$( echo "${WAN_DEV_PROPERTY_LIST}" | awk '$1 == "'"${ifn}"'" {print "port="$4"; str="$1; exit;}' )"
        [ -z "${port}" ] && break
        ! echo "${RT_DEV_LIST}" | grep -q "^${port}$" && break
        tableID="$( get_sub_rt_id "4" "${port}" )"
        [ -z "${tableID}" ] && break
        ip rule add from "0.0.0.0" table "${tableID}" prio "${CUSTOM_PRIO}" > /dev/null 2>&1
        ip route flush cache > /dev/null 2>&1
        break
    done
    if [ "${WAN_AVAL_NUM}" = "0" ]; then
        str="None"
    elif [ -z "${tableID}" ]; then
        str="$( get_main_rt_default_dev "4" )"
        [ -n "${str}" ] && str="$( echo "${WAN_DEV_PROPERTY_LIST}" | awk '$4 == "'"${str}"'" {print $5; exit;}' )"
        [ -n "${str}" ] && str="$( echo "${WAN_DEV_LIST}" | awk '$2 == "'"${str}"'" {print $1; exit;}' )"
        [ -z "${str}" ] && str="None"
    fi
    strbuf="$( printf "%s %-16s %-16s %s\n" "[$$]:  " "Host" "IPv4" "${str}" )"
    echo "$(lzdate) ${MY_LINE}"
    logger -p 1 "${MY_LINE}"
    echo "$(lzdate) ${strbuf}"
    logger -p 1 "${strbuf}"
    ifn="" port="" str="System" tableID=""
    while true
    do
        [ "${HOST_V6_WAN_PORT}" -ge "${MAX_WAN_PORT}" ] && break
        ifn="$( echo "${WAN_V6_DEV_LIST}" | awk 'NR == (1 + "'"${HOST_V6_WAN_PORT}"'") && $1 !~ /X$/ && $2 !~ /X$/ {print $1; exit;}' )"
        [ -z "${ifn}" ] && break
        eval "$( echo "${WAN_DEV_PROPERTY_LIST}" | awk '$1 == "'"${ifn}"'" {print "port="$4"; str="$1; exit;}' )"
        [ -z "${port}" ] && break
        ! echo "${RT_V6_DEV_LIST}" | grep -q "^${port}$" && break
        tableID="$( get_sub_rt_id "6" "${port}" )"
        [ -z "${tableID}" ] && break
        ip -6 rule add from "::" table "${tableID}" prio "${CUSTOM_PRIO}" > /dev/null 2>&1
        ip -6 route flush cache > /dev/null 2>&1
        break
    done
    if [ "${WAN_V6_AVAL_NUM}" = "0" ]; then
        str="None"
    elif [ -z "${tableID}" ]; then
        str="$( get_main_rt_default_dev "6" )"
        [ -n "${str}" ] && str="$( echo "${WAN_DEV_PROPERTY_LIST}" | awk '$4 == "'"${str}"'" {print $5; exit;}' )"
        [ -n "${str}" ] && str="$( echo "${WAN_V6_DEV_LIST}" | awk '$2 == "'"${str}"'" {print $1; exit;}' )"
        [ -z "${str}" ] && str="None"
    fi
    strbuf="$( printf "%s %-16s %-16s %s\n" "[$$]:  " "$( printf "%4s" "" )" "IPv6" "${str}" )"
    echo "$(lzdate) ${strbuf}"
    logger -p 1 "${strbuf}"
}

print_ipv4_address_list() {
    sed -e 's/^[[:space:]]\+//g' -e 's/[[:space:]#].*$//g' \
        -e 's/\(^\|[^[:digit:]]\)[0]\+\([[:digit:]]\)/\1\2/g' \
        -e "/^$( echo "${regex_v4}" | sed 's/[(){}|+?]/\\&/g' )$/!d" \
        -e 's/\/32//g' "${1}" \
        | awk 'function fix_cidr(ipa) {
            split(ipa, arr, /\.|\//);
            if (arr[5] !~ /^[0-9][0-9]?$/)
                ip_value = ipa;
            else {
                pos = int(arr[5] / 8) + 1;
                step = rshift(255, arr[5] % 8) + 1;
                for (i = pos; i < 5; ++i) {
                    if (i == pos)
                        arr[i] = int(arr[i] / step) * step;
                    else
                        arr[i] = 0;
                }
                ip_value = arr[1]"."arr[2]"."arr[3]"."arr[4]"/"arr[5];
            }
            delete arr;
            return ip_value;
        } \
        NF == 1 && !i[$1]++ {print fix_cidr($1);}' \
        | awk 'NF == 1 && $1 != "0.0.0.0/0" && !i[$1]++ {print $1}'
}

print_ipv6_address_list() {
    sed -e 's/^[[:space:]]\+//g' -e 's/[[:space:]#].*$//g' \
        -e 's/\(^\|[\:\/\%]\)[0]\+\([[:digit:]]\)/\1\2/g' \
        -e "/^$( echo "${regex_v6}" | sed 's/[(){}|+?]/\\&/g' )$/!d" \
        -e 's/\/128//g' "${1}" \
        | awk 'NF == 1 && !i[$1]++ {print tolower($1)}'
}

delete_custom_rule() {
    eval "$( ip rule show 2> /dev/null | awk -v count="0" '$1 == "'"${CUSTOM_PRIO}:"'" \
        && $2 == "from" && $3 ~ "'"^${regex_v4%"([\/]("*}$"'" && $4 == "lookup" && NF == 5 {
        print "ip rule del "$2" "$3" table "$5" prio ""'"${CUSTOM_PRIO}"'"" > /dev/null 2>&1";
        count++;
    } END{
        if (count != "0")
            print "ip route flush cache > /dev/null 2>&1";
    }' )"
    eval "$( ip -6 rule show 2> /dev/null | awk -v count="0" '$1 == "'"${CUSTOM_PRIO}:"'" \
        && $2 == "from" && $3 ~ "'"^${regex_v6%"([\/]("*}$"'" && $4 == "lookup" && NF == 5 {
        print "ip -6 rule del "$2" "$3" table "$5" prio ""'"${CUSTOM_PRIO}"'"" > /dev/null 2>&1";
        count++;
    } END{
        if (count != "0")
            print "ip -6 route flush cache > /dev/null 2>&1";
    }' )"
}

delete_ipsets() {
    local index="0"
    until [ "${index}" -ge "${MAX_WAN_PORT}" ]
    do
        eval ipset -q flush "\${ISPIP_SET_${index}}" && eval ipset -q destroy "\${ISPIP_SET_${index}}"
        eval ipset -q flush "\${ISPIP_V6_SET_${index}}" && eval ipset -q destroy "\${ISPIP_V6_SET_${index}}"
        index="$(( index + 1 ))"
    done
    ipset -q flush "${ISPIP_SET_B}" && ipset -q destroy "${ISPIP_SET_B}"
    ipset -q flush "${ISPIP_V6_SET_B}" && ipset -q destroy "${ISPIP_V6_SET_B}"
    [ ! -f "${CUSTOM_IPSETS_TMP_LST_FILENAME}" ] && return
    sed -e '/^[[:space:]]*[#]/d' -e 's/[#].*$//g' -e '/^[[:space:]]*$/d' "${CUSTOM_IPSETS_TMP_LST_FILENAME}" \
        | awk '{if ($1 != "") system("ipset -q flush "$1" && ipset -q destroy "$1)}'
    sed -i '1,$d' "${CUSTOM_IPSETS_TMP_LST_FILENAME}" > /dev/null 2>&1
    if [ "${CUSTOM_IPSETS}" != "0" ] && [ "${CUSTOM_V6_IPSETS}" != "0" ] && [ "${DNAME_IPSETS}" != "0" ]; then
        rm -f "${CUSTOM_IPSETS_TMP_LST_FILENAME}" > /dev/null 2>&1
    fi
}

create_ipsets() {
    local index="0"  item=""
    until [ "${index}" -ge "${MAX_WAN_PORT}" ]
    do
        if eval grep -q "^[^#]*\'\${ISPIP_SET_${index}}\'" "${MWAN3_FILENAME}" 2> /dev/null; then
            eval ipset -q create "\${ISPIP_SET_${index}}" hash:net maxelem 4294967295 #--hashsize 1024 mexleme 65536
            eval ipset -q flush "\${ISPIP_SET_${index}}"
        fi
        if eval grep -q "^[^#]*\'\${ISPIP_V6_SET_${index}}\'" "${MWAN3_FILENAME}" 2> /dev/null; then
            eval ipset -q create "\${ISPIP_V6_SET_${index}}" hash:net family ipv6 maxelem 4294967295 #--hashsize 1024 mexleme 65536
            eval ipset -q flush "\${ISPIP_V6_SET_${index}}"
        fi
        index="$(( index + 1 ))"
    done
    if grep -q "^[^#]*\'${ISPIP_SET_B}\'" "${MWAN3_FILENAME}" 2> /dev/null; then
        ipset -q create "${ISPIP_SET_B}" hash:net maxelem 4294967295 #--hashsize 1024 mexleme 65536
        ipset -q flush "${ISPIP_SET_B}"
    fi
    if grep -q "^[^#]*\'${ISPIP_V6_SET_B}\'" "${MWAN3_FILENAME}" 2> /dev/null; then
        ipset -q create "${ISPIP_V6_SET_B}" hash:net family ipv6 maxelem 4294967295 #--hashsize 1024 mexleme 65536
        ipset -q flush "${ISPIP_V6_SET_B}"
    fi
    if [ "${CUSTOM_IPSETS}" = "0" ] && [ -f "${CUSTOM_IPSETS_LST_FILENAME}" ]; then
        CUSTOM_IPSETS_LST="$( sed -e 's/[[:space:]]\+/ /g' -e '/^[[:space:]]*[#]/d' -e 's/^[[:space:]]//g' -e '/^[[:space:]]*$/d' "${CUSTOM_IPSETS_LST_FILENAME}" 2> /dev/null \
                            | grep -Eo '^[^[:space:]=#]+[=][^[:space:]=#]+' )"
        for item in ${CUSTOM_IPSETS_LST}
        do
            if grep -q "^[^#]*\'${item%=*}\'" "${MWAN3_FILENAME}" 2> /dev/null; then
                ipset -q create "${item%=*}" hash:net maxelem 4294967295 #--hashsize 1024 mexleme 65536
                ipset -q flush "${item%=*}"
            fi
        done
    fi
    if [ "${CUSTOM_V6_IPSETS}" = "0" ] && [ -f "${CUSTOM_V6_IPSETS_LST_FILENAME}" ]; then
        CUSTOM_V6_IPSETS_LST="$( sed -e 's/[[:space:]]\+/ /g' -e '/^[[:space:]]*[#]/d' -e 's/^[[:space:]]//g' -e '/^[[:space:]]*$/d' "${CUSTOM_IPSETS_LST_FILENAME}" 2> /dev/null \
                            | grep -Eo '^[^[:space:]=#]+[=][^[:space:]=#]+' )"
        for item in ${CUSTOM_V6_IPSETS_LST}
        do
            if grep -q "^[^#]*\'${item%=*}\'" "${MWAN3_FILENAME}" 2> /dev/null; then
                ipset -q create "${item%=*}" hash:net family ipv6 maxelem 4294967295 #--hashsize 1024 mexleme 65536
                ipset -q flush "${item%=*}"
            fi
        done
    fi
    if [ "${DNAME_IPSETS}" = "0" ] && [ -f "${DNAME_IPSETS_LST_FILENAME}" ]; then
        DNAME_IPSETS_LST="$( sed -e 's/[[:space:]]\+/ /g' -e '/^[[:space:]]*[#]/d' -e 's/^[[:space:]]//g' -e '/^[[:space:]]*$/d' "${DNAME_IPSETS_LST_FILENAME}" 2> /dev/null \
                            | awk '{print $1}' )"
        for item in ${DNAME_IPSETS_LST}
        do
            ipset -q create "${item}" hash:ip maxelem 4294967295 #--hashsize 1024 mexleme 65536
            ipset -q flush "${item}"
        done
    fi
}

add_net_address_sets() {
    if [ ! -s "${1}" ] || [ -z "${2}" ]; then return; fi;
    ipset -q create "${2}" hash:net maxelem 4294967295 #--hashsize 1024 mexleme 65536
    print_ipv4_address_list "${1}" | awk 'NF >= 1 {print "'"-! del ${2} "'"$1"'"\n-! add ${2} "'"$1} END{print "COMMIT"}' | ipset restore > /dev/null 2>&1
}

get_ipv4_data_file_item_total() {
    local retval="0"
    [ -s "${1}" ] && {
        retval="$( print_ipv4_address_list "${1}" 2> /dev/null \
            | awk -v count="0" 'NF >= 1 {count++} END{print count}' )"
    }
    echo "${retval}"
}

add_ipv6_net_address_sets() {
    if [ ! -s "${1}" ] || [ -z "${2}" ]; then return; fi;
    ipset -q create "${2}" hash:net family ipv6 maxelem 4294967295 #--hashsize 1024 mexleme 65536
    print_ipv6_address_list "${1}" | awk 'NF >= 1 {print "'"-! del ${2} "'"$1"'"\n-! add ${2} "'"$1} END{print "COMMIT"}' | ipset restore > /dev/null 2>&1
}

get_ipv6_data_file_item_total() {
    local retval="0"
    [ -s "${1}" ] && {
        retval="$( print_ipv6_address_list "${1}" 2> /dev/null \
            | awk -v count="0" 'NF >= 1 {count++} END{print count}' )"
    }
    echo "${retval}"
}

get_wan_list() {
    local wan_list="$( uci show mwan3 2> /dev/null \
            | awk -F '.' '$0 ~ "'"ipset=\'${1}\'"'" && $2 != "" {system("uci get mwan3."$2".use_policy 2> /dev/null");}' \
            | awk '$1 != "" {system("uci get mwan3."$1".use_member 2> /dev/null");}' \
            | sed -e 's/[[:space:]]\+/\n/g'  -e '/^[[:space:]]*$/d' \
            | awk '$1 != "" {system("uci get mwan3."$1".interface  2> /dev/null");}' )"
    echo "${wan_list}"
}

get_ipset_total() {
    ipset -q list "${1}" | awk -v count="0" '$1 ~ "'"^${regex_v4}$"'" {count++} END{print count}'
}

get_ipv6_ipset_total() {
    ipset -q list "${1}" | awk -v count="0" '$1 ~ "'"^${regex_v6}$"'" {count++} END{print count}'
}

print_wan_ispip_item_num() {
    local index="0" name="" num="0" wan="" lined="0"
    until [ "${index}" -ge "${MAX_WAN_PORT}" ]
    do
        eval name="\${ISPIP_SET_${index}}"
        if [ "$( ipset -q -n list "${name}" )" ]; then
            [ "${lined}" = "0" ] && {
                lined="1"
                echo "$(lzdate) ${MY_LINE}"
                logger -p 1 "${MY_LINE}"
            }
            num="$( get_ipset_total "${name}" )"
            wan="$( get_wan_if "$( get_wan_property_dev "$( get_wan_list "${name}" )" )" )"
            if [ -n "${wan}" ]; then
                for wan in ${wan}
                do
                    printf "%s %-13s %-19s %s\n" "$(lzdate) [$$]:  " "${wan}" "${name}" "${num}"
                    logger -p 1 "$( printf "%s %-13s %-19s %s\n" "[$$]:  " "${wan}" "${name}" "${num}" )"
                done
            else
                wan="$( get_wan_name "${index}" )"
                printf "%s %-13s %-19s %s\n" "$(lzdate) [$$]:  " "${wan}" "${name}" "${num}"
                logger -p 1 "$( printf "%s %-13s %-19s %s\n" "[$$]:  " "${wan}" "${name}" "${num}" )"
            fi
        fi
        index="$(( index + 1 ))"
    done
    if [ "$( ipset -q -n list "${ISPIP_SET_B}" )" ]; then
        [ "${lined}" = "0" ] && {
            lined="1"
            echo "$(lzdate) ${MY_LINE}"
            logger -p 1 "${MY_LINE}"
        }
        num="$( get_ipset_total "${ISPIP_SET_B}" )"
        wan="$( get_wan_if "$( get_wan_property_dev "$( get_wan_list "${ISPIP_SET_B}" )" )" )"
        if [ -n "${wan}" ]; then
            for wan in ${wan}
            do
                printf "%s %-13s %-19s %s\n" "$(lzdate) [$$]:  " "${wan}" "${ISPIP_SET_B}" "${num}"
                logger -p 1 "$( printf "%s %-13s %-19s %s\n" "[$$]:  " "${wan}" "${ISPIP_SET_B}" "${num}" )"
            done
        else
            wan="LBX"
            printf "%s %-13s %-19s %s\n" "$(lzdate) [$$]:  " "${wan}" "${ISPIP_SET_B}" "${num}"
            logger -p 1 "$( printf "%s %-13s %-19s %s\n" "[$$]:  " "${wan}" "${ISPIP_SET_B}" "${num}" )"
        fi
    fi
    lined="0"
    if [ -n "${CUSTOM_IPSETS_LST}" ]; then
        for name in ${CUSTOM_IPSETS_LST}
        do
            [ "${lined}" = "0" ] && {
                lined="1"
                echo "$(lzdate) ${MY_LINE}"
                logger -p 1 "${MY_LINE}"
            }
            num="$( get_ipset_total "${name%=*}" )"
            wan="$( get_wan_if "$( get_wan_property_dev "$( get_wan_list "${name%=*}" )" )" )"
            if [ -n "${wan}" ]; then
                for wan in ${wan}
                do
                    printf "%s %-13s %-19s %s\n" "$(lzdate) [$$]:  " "${wan}" "${name%=*}" "${num}"
                    logger -p 1 "$( printf "%s %-13s %-19s %s\n" "[$$]:  " "${wan}" "${name%=*}" "${num}" )"
                done
            else
                wan="wanX"
                printf "%s %-13s %-19s %s\n" "$(lzdate) [$$]:  " "${wan}" "${name%=*}" "${num}"
                logger -p 1 "$( printf "%s %-13s %-19s %s\n" "[$$]:  " "${wan}" "${name%=*}" "${num}" )"
            fi
        done
    fi
    lined="0"
    if [ -n "${DNAME_IPSETS_LST}" ]; then
        local buf=""
        for name in ${DNAME_IPSETS_LST}
        do
            [ "${lined}" = "0" ] && {
                lined="1"
                echo "$(lzdate) ${MY_LINE}"
                logger -p 1 "${MY_LINE}"
            }
            buf="$( uci show "${HOST_DHCP_FILENAME}" 2> /dev/null | awk -F '.' '$2 ~ /^@ipset/ && $3 ~ "'"^name=.*\'${name}\'"'" {print $2}' )"
            [ -n "${buf}" ] && buf="$( uci get "${HOST_DHCP_FILENAME}.${buf}.domain" 2> /dev/null | awk '{print NF; exit}' )"
            [ -z "${buf}" ] && buf="0"
            num="$( get_ipset_total "${name}" )"
            wan="$( get_wan_if "$( get_wan_property_dev "$( get_wan_list "${name}" )" )" )"
            if [ -n "${wan}" ]; then
                for wan in ${wan}
                do
                    printf "%s %-13s %-19s %s%s\n" "$(lzdate) [$$]:  " "${wan}" "${name}" "${num}" "[${buf}]"
                    logger -p 1 "$( printf "%s %-13s %-19s %s%s\n" "[$$]:  " "${wan}" "${name}" "${num}" "[${buf}]" )"
                done
            else
                wan="wanX"
                printf "%s %-13s %-19s %s%s\n" "$(lzdate) [$$]:  " "${wan}" "${name}" "${num}" "(${buf})"
                logger -p 1 "$( printf "%s %-13s %-19s %s%s\n" "[$$]:  " "${wan}" "${name}" "${num}" "[${buf}]" )"
            fi
        done
    fi
}

print_ipv6_wan_ispip_item_num() {
    local index="0" name="" num="0" wan="" lined="0"
    until [ "${index}" -ge "${MAX_WAN_PORT}" ]
    do
        eval name="\${ISPIP_V6_SET_${index}}"
        if [ "$( ipset -q -n list "${name}" )" ]; then
            [ "${lined}" = "0" ] && {
                lined="1"
                echo "$(lzdate) ${MY_LINE}"
                logger -p 1 "${MY_LINE}"
            }
            num="$( get_ipv6_ipset_total "${name}" )"
            wan="$( get_wan_if_v6 "$( get_wan_property_dev "$( get_wan_list "${name}" )" )" )"
            if [ -n "${wan}" ]; then
                for wan in ${wan}
                do
                    printf "%s %-13s %-19s %s\n" "$(lzdate) [$$]:  " "${wan}" "${name}" "${num}"
                    logger -p 1 "$( printf "%s %-13s %-19s %s\n" "[$$]:  " "${wan}" "${name}" "${num}" )"
                done
            else
                wan="$( get_wan_name_v6 "${index}" )"
                printf "%s %-13s %-19s %s\n" "$(lzdate) [$$]:  " "${wan}" "${name}" "${num}"
                logger -p 1 "$( printf "%s %-13s %-19s %s\n" "[$$]:  " "${wan}" "${name}" "${num}" )"
            fi
        fi
        index="$(( index + 1 ))"
    done
    if [ "$( ipset -q -n list "${ISPIP_V6_SET_B}" )" ]; then
        [ "${lined}" = "0" ] && {
            lined="1"
            echo "$(lzdate) ${MY_LINE}"
            logger -p 1 "${MY_LINE}"
        }
        num="$( get_ipv6_ipset_total "${ISPIP_V6_SET_B}" )"
        wan="$( get_wan_if_v6 "$( get_wan_property_dev "$( get_wan_list "${ISPIP_V6_SET_B}" )" )" )"
        if [ -n "${wan}" ]; then
            for wan in ${wan}
            do
                printf "%s %-13s %-19s %s\n" "$(lzdate) [$$]:  " "${wan}" "${ISPIP_V6_SET_B}" "${num}"
                logger -p 1 "$( printf "%s %-13s %-19s %s\n" "[$$]:  " "${wan}" "${ISPIP_V6_SET_B}" "${num}" )"
            done
        else
            wan="LBX"
            printf "%s %-13s %-19s %s\n" "$(lzdate) [$$]:  " "${wan}" "${ISPIP_V6_SET_B}" "${num}"
            logger -p 1 "$( printf "%s %-13s %-19s %s\n" "[$$]:  " "${wan}" "${ISPIP_V6_SET_B}" "${num}" )"
        fi
    fi
    lined="0"
    if [ -n "${CUSTOM_V6_IPSETS_LST}" ]; then
        for name in ${CUSTOM_V6_IPSETS_LST}
        do
            [ "${lined}" = "0" ] && {
                lined="1"
                echo "$(lzdate) ${MY_LINE}"
                logger -p 1 "${MY_LINE}"
            }
            num="$( get_ipv6_ipset_total "${name%=*}" )"
            wan="$( get_wan_if_v6 "$( get_wan_property_dev "$( get_wan_list "${name%=*}" )" )" )"
            if [ -n "${wan}" ]; then
                for wan in ${wan}
                do
                    printf "%s %-13s %-19s %s\n" "$(lzdate) [$$]:  " "${wan}" "${name%=*}" "${num}"
                    logger -p 1 "$( printf "%s %-13s %-19s %s\n" "[$$]:  " "${wan}" "${name%=*}" "${num}" )"
                done
            else
                wan="wanX"
                printf "%s %-13s %-19s %s\n" "$(lzdate) [$$]:  " "${wan}" "${name%=*}" "${num}"
                logger -p 1 "$( printf "%s %-13s %-19s %s\n" "[$$]:  " "${wan}" "${name%=*}" "${num}" )"
            fi
        done
    fi
}

get_isp_name() {
    local retval="FOREIGN/Unknown" index="0" tmp_isp_set="lz_tmp_isp_set"
    if [ -n "${1}" ]; then
        until [ "${index}" -ge "${ISP_TOTAL}" ]
        do
            eval add_net_address_sets "\${PATH_DATA}/\${ISP_DATA_${index}}" "${tmp_isp_set}"
            if ipset -q test "${tmp_isp_set}" "${1}"; then
                eval retval="\${ISP_NAME_${index}}"
                break
            fi
            ipset -q flush "${tmp_isp_set}"
            index="$(( index + 1 ))"
        done
        ipset -q destroy "${tmp_isp_set}"
    fi
    echo "${retval}"
}

get_isp_name_v6() {
    local retval="FOREIGN/Unknown_V6" index="0" tmp_isp_set="lz_tmp_isp_v6_set"
    if echo "${1}" | grep -Eq "^${regex_v6}$"; then
        if echo "${1}" | grep -q '^[fF][eE][89abAB][0-9a-fA-F]:'; then
            retval="LOCAL"
        elif echo "${1}" | grep -q '^[fF][cdCD][0-9a-fA-F]{2}:'; then
            retval="PRIVATE"
        else
            until [ "${index}" -ge "${ISP_TOTAL}" ]
            do
                eval add_ipv6_net_address_sets "\${PATH_DATA}/\${ISP_V6_DATA_${index}}" "${tmp_isp_set}"
                if ipset -q test "${tmp_isp_set}" "${1}"; then
                    eval retval="\${ISP_V6_NAME_${index}}"
                    break
                elif echo "${1}" | grep -q '^[fF][cdCD][0-9a-fA-F]{2}:'; then
                    retval="PRIVATE"
                    break
                elif echo "${1}" | grep -q '^[fF][eE][89abAB][0-9a-fA-F]:'; then
                    retval="LOCAL"
                    break
                fi
                ipset -q flush "${tmp_isp_set}"
                index="$(( index + 1 ))"
            done
            ipset -q destroy "${tmp_isp_set}"
        fi
    fi
    echo "${retval}"
}

print_wan_ip() {
    local tableID=""
    local ifn="" ifx="" item="" lined="0"
    for ifn in ${RT_DEV_LIST}
    do
        [ "${lined}" = "0" ] && {
            lined="1"
            echo "$(lzdate) ${MY_LINE}"
            logger -p 1 "${MY_LINE}"
        }
        tableID="$( get_sub_rt_id "4" "${ifn}" )"
        [ -n "${tableID}" ] && {
            ip rule add from "0.0.0.0" table "${tableID}" prio "${CUSTOM_PRIO}" > /dev/null 2>&1
            ip route flush cache > /dev/null 2>&1
        }
        ifx="$( get_wan_if "${ifn}" )"
        eval "$( ip -4 -o address show dev "${ifn}" 2> /dev/null \
            | awk 'NF != 0 {
                ifa=$4;
                gsub(/\/.*$/, "", ifa);
                if ("'"${tableID}"'" != "") {
                    print $2,ifa,system("wget -T 10 ""'" -qO - ${PIPDN}"'"" 2> /dev/null | grep -Eo \"""'"${regex_v4%"([\/]("*}"'""\" | sed -n 1p");
                } else
                    print $2,ifa,system("wget -T 10 --bind-address="ifa"'" -qO - ${PIPDN}"'"" 2> /dev/null | grep -Eo \"""'"${regex_v4%"([\/]("*}"'""\" | sed -n 1p");
            }' \
            | awk 'NF >= 2 {
                if ($3 !~ "'"^${regex_v4%"([\/]("*}$"'") {
                    if ("'"${tableID}"'" != "") {
                        print $1,$2,system("wget -T 10 ""'" -qO - ${PIPDNX}"'"" 2> /dev/null | grep -Eo \"""'"${regex_v4%"([\/]("*}"'""\" | sed -n 1p");
                    } else
                        print $1,$2,system("wget -T 10 --bind-address="$2"'" -qO - ${PIPDNX}"'"" 2> /dev/null | grep -Eo \"""'"${regex_v4%"([\/]("*}"'""\" | sed -n 1p");
                } else
                    print $0;
            }' \
            | awk 'NF >= 2 {
                print "echo "$1" "$2" \"\$( get_isp_name \""$3"\" )\" "$3;
        }' )" \
            | awk 'NF >= 2 {
                wanip="Public IP Unobtainable.";
                isp="";
                if ($4 ~ "'"^${regex_v4%"([\/]("*}$"'") {wanip=$4; isp=$3;}
                strbuf=sprintf("%s   %-8s %-16s %-15s %s","'"[$$]:"'","'"${ifx}"'",$2,wanip,isp);
                printf("%s %s\n","'"$(lzdate)"'",strbuf);
                system("logger -p 1 \""strbuf"\"");
        }'
        [ -n "${tableID}" ] && {
            ip rule del from "0.0.0.0" table "${tableID}" prio "${CUSTOM_PRIO}" > /dev/null 2>&1
            ip route flush cache > /dev/null 2>&1
        }
    done
    lined="0"
    local strbuf="" count="0"
    ifn=""
    for ifn in ${RT_V6_DEV_LIST}
    do
        ifx="$( get_wan_if_v6 "$( get_wan_dev "${ifn#*pppoe-}" )" )"
        echo "${ifn}" | grep -q '^pppoe-' && ifx="${ifx} pppoe"
        item="$( ip -6 -o address show dev "${ifn}" 2> /dev/null \
            | awk 'NF != 0 {
                ifa=$4;
                gsub(/\/.*$/, "", ifa);
                print ifa;
            }' )"
        count="0"
        for item in ${item}
        do
            if [ "${count}" = "0" ]; then
                strbuf="$( printf "%s %-8s %s %s\n" "[$$]:  " "${ifx}" "${item}" "$( get_isp_name_v6 "${item}" )" )"
            else
                strbuf="$( printf "%s %-8s %s %s\n" "[$$]:  " "$( printf "%${#ifx}s" "" )" "${item}" "$( get_isp_name_v6 "${item}" )" )"
            fi
            [ "${lined}" = "0" ] && {
                lined="1"
                echo "$(lzdate) ${MY_LINE}"
                logger -p 1 "${MY_LINE}"
            }
            echo "$(lzdate) ${strbuf}"
            logger -p 1 "${strbuf}"
            count="$(( count + 1 ))"
        done
    done
}

load_ipsets() {
    local index="0" port="0" name="" num="0" wan="0" buf=""
    until [ "${index}" -ge "${ISP_TOTAL}" ]
    do
        eval port="\${ISP_${index}_WAN_PORT}"
        if [ "${port}" -lt "${MAX_WAN_PORT}" ]; then
            eval add_net_address_sets "\${PATH_DATA}/\${ISP_DATA_${index}}" "\${ISPIP_SET_${port}}"
            wan="$( get_wan_name "${port}" )"
        elif [ "${port}" = "${MAX_WAN_PORT}" ]; then
            eval add_net_address_sets "\${PATH_DATA}/\${ISP_DATA_${index}}" "${ISPIP_SET_B}"
            wan="LB"
        else
            wan="mwan3"
        fi
        eval name="\${ISP_NAME_${index}}"
        eval num="\$( get_ipv4_data_file_item_total \"\${PATH_DATA}/\${ISP_DATA_${index}}\" )"
        printf "%s %-16s %-16s %s\n" "$(lzdate) [$$]:  " "${name}" "${wan}" "${num}" 
        logger -p 1 "$( printf "%s %-16s %-16s %s\n" "[$$]:  " "${name}" "${wan}" "${num}" )"
        index="$(( index + 1 ))"
    done
    echo "$(lzdate) ${MY_LINE}"
    logger -p 1 "${MY_LINE}"
    index="0"
    until [ "${index}" -ge "${ISP_TOTAL}" ]
    do
        eval port="\${ISP_${index}_WAN_PORT_V6}"
        if [ "${port}" -lt "${MAX_WAN_PORT}" ]; then
            eval add_ipv6_net_address_sets "\${PATH_DATA}/\${ISP_V6_DATA_${index}}" "\${ISPIP_V6_SET_${port}}"
            wan="$( get_wan_name_v6 "${port}" )"
        elif [ "${port}" = "${MAX_WAN_PORT}" ]; then
            eval add_ipv6_net_address_sets "\${PATH_DATA}/\${ISP_V6_DATA_${index}}" "${ISPIP_V6_SET_B}"
            wan="LB"
        else
            wan="mwan3"
        fi
        eval name="\${ISP_V6_NAME_${index}}"
        eval num="\$( get_ipv6_data_file_item_total \"\${PATH_DATA}/\${ISP_V6_DATA_${index}}\" )"
        printf "%s %-16s %-16s %s\n" "$(lzdate) [$$]:  " "${name}" "${wan}" "${num}" 
        logger -p 1 "$( printf "%s %-16s %-16s %s\n" "[$$]:  " "${name}" "${wan}" "${num}" )"
        index="$(( index + 1 ))"
    done
    for name in ${CUSTOM_IPSETS_LST}
    do
        add_net_address_sets "$( echo "${name#*=}" | sed -e 's/\"//g' -e "s/\'//g" )" "${name%=*}"
        echo "${name%=*}" >> "${CUSTOM_IPSETS_TMP_LST_FILENAME}" 2> /dev/null
    done
    for name in ${CUSTOM_V6_IPSETS_LST}
    do
        add_ipv6_net_address_sets "$( echo "${name#*=}" | sed -e 's/\"//g' -e "s/\'//g" )" "${name%=*}"
        echo "${name%=*}" >> "${CUSTOM_IPSETS_TMP_LST_FILENAME}" 2> /dev/null
    done
    [ -n "${DNAME_IPSETS_LST}" ] && /etc/init.d/dnsmasq restart > /dev/null 2>&1
    for name in ${DNAME_IPSETS_LST}
    do
        buf="$( uci show "${HOST_DHCP_FILENAME}" 2> /dev/null | awk -F '.' '$2 ~ /^@ipset/ && $3 ~ "'"^name=.*\'${name}\'"'" {print $2}' )"
        [ -n "${buf}" ] && uci get "${HOST_DHCP_FILENAME}.${buf}.domain" 2> /dev/null \
                                | sed -e 's/[[:space:]]\+/\n/g' -e '/^[[:space:]]*$/d' \
                                | awk '{system("nslookup -type=a "$1" > /dev/null 2>&1")}'
        echo "${name}" >> "${CUSTOM_IPSETS_TMP_LST_FILENAME}" 2> /dev/null
    done
    [ -z "${CUSTOM_IPSETS_LST}" ] && [ -z "${DNAME_IPSETS_LST}" ] && [ -f "${CUSTOM_IPSETS_TMP_LST_FILENAME}" ] \
        && rm -f "${CUSTOM_IPSETS_TMP_LST_FILENAME}" > /dev/null 2>&1
    print_wan_ispip_item_num
    print_ipv6_wan_ispip_item_num
    print_wan_ip
    add_host_port_rule
}

create_url_list() {
    local index="0"
    until [ "${index}" -ge "${ISP_TOTAL}" ]
    do
        eval echo "\${UPDATE_ISPIP_DATA_DOWNLOAD_URL}/\${ISP_DATA_${index}}" >> "${PATH_TMP_DATA}/${ISPIP_FILE_URL_LIST}" 2> /dev/null
        index="$(( index + 1 ))"
    done
    index="0"
    until [ "${index}" -ge "${ISP_TOTAL}" ]
    do
        eval echo "\${UPDATE_ISPIP_DATA_DOWNLOAD_URL}/\${ISP_V6_DATA_${index}}" >> "${PATH_TMP_DATA}/${ISPIP_FILE_URL_LIST}" 2> /dev/null
        index="$(( index + 1 ))"
    done
}

update_isp_data() {
    # 去苍狼山庄（https://ispip.clang.cn/）下载ISP网络运营商CIDR网段数据文件
    echo "$(lzdate)" [$$]: Start to update the ISP IP data files...
    logger -p 1 "[$$]: Start to update the ISP IP data files..."
    [ ! -d "${PATH_DATA}" ] && mkdir -p "${PATH_DATA}" > /dev/null 2>&1
    [ ! -d "${PATH_TMP_DATA}" ] && mkdir -p "${PATH_TMP_DATA}" > /dev/null 2>&1
    rm -f "${PATH_TMP_DATA}/"* > /dev/null 2>&1
    create_url_list
    local COOKIES_STR="" retval="1" retry_count="1"
    local retry_limit="$(( RETRY_NUM + retry_count ))"
    while [ "${retry_count}" -le "${retry_limit}" ]
    do
        [ ! -f "${PATH_DATA}/cookies.isp" ] && COOKIES_STR="--save-cookies=${PATH_DATA}/cookies.isp" || COOKIES_STR="--load-cookies=${PATH_DATA}/cookies.isp"
        eval "wget -q -nc -c --timeout=20 --random-wait --user-agent=\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.5304.88 Safari/537.36 Edg/108.0.1462.46\" --referer=${UPDATE_ISPIP_DATA_DOWNLOAD_URL} ${COOKIES_STR} --keep-session-cookies --no-check-certificate -P ${PATH_TMP_DATA} -i ${PATH_TMP_DATA}/${ISPIP_FILE_URL_LIST} 2> /dev/null"
        if [ "$( find "${PATH_TMP_DATA}" -name "*_cidr.txt" -print0 2> /dev/null | awk '{} END{print NR}' )" -ge "${ISP_TOTAL}" ] \
            && [ "$( find "${PATH_TMP_DATA}" -name "*_ipv6.txt" -print0 2> /dev/null | awk '{} END{print NR}' )" -ge "${ISP_TOTAL}" ]; then
            retval="0"
            break
        fi
        retry_count="$(( retry_count + 1 ))"
        sleep "5s"
    done
    if [ "${retval}" = "0" ]; then
        echo "$(lzdate)" [$$]: Download the ISP IP data files successfully.
        logger -p 1 "[$$]: Download the ISP IP data files successfully."
        ! mv -f "${PATH_TMP_DATA}"/*"_cidr.txt" "${PATH_DATA}" > /dev/null 2>&1 && retval="1"
        ! mv -f "${PATH_TMP_DATA}"/*"_ipv6.txt" "${PATH_DATA}" > /dev/null 2>&1 && retval="1"
        [ "${retval}" != "0" ] && {
            echo "$(lzdate)" [$$]: Failed to copy the ISP IP data files.
            logger -p 1 "[$$]: Failed to copy the ISP IP data files."
        }
    else
        echo "$(lzdate)" [$$]: Failed to download the ISP IP data files.
        logger -p 1 "[$$]: Failed to download the ISP IP data files."
    fi
    echo "$(lzdate)" [$$]: Remove the temporary files.
    logger -p 1 "[$$]: Remove the temporary files."
    rm -f "${PATH_TMP_DATA}"/* > /dev/null 2>&1
    if [ "${retval}" = "0" ]; then
        echo "$(lzdate)" [$$]: Update the ISP IP data files successfully.
        echo "$(lzdate) ${MY_LINE}"
        logger -p 1 "[$$]: Update the ISP IP data files successfully."
        logger -p 1 "${MY_LINE}"
    else
        echo "$(lzdate)" [$$]: Failed to update the ISP IP data files.
        logger -p 1 "[$$]: Failed to update the ISP IP data files."
    fi
    return "${retval}"
}

check_isp_data() {
    local index="0"
    until [ "${index}" -ge "${ISP_TOTAL}" ]
    do
        eval [ ! -f "\${PATH_DATA}/\${ISP_DATA_${index}}" ] && return "1"
        index="$(( index + 1 ))"
    done
    return "0"
}

load_update_task() {
    echo "$(lzdate) ${MY_LINE}"
    logger -p 1 "${MY_LINE}"
    if [ "${INTERVAL_DAY}" = "0" ]; then
        echo "$(lzdate)" [$$]: The scheduled update task was not started.
        logger -p 1 "[$$]: The scheduled update task was not started."
        if crontab -l 2> /dev/null | grep -q "^[^#]*${PROJECT_ID}"; then
            sed -i "/^[^#]*${PROJECT_ID}/d" "${CRONTABS_ROOT_FILENAME}" > /dev/null 2>&1
            echo "$(lzdate)" [$$]: The previous scheduled update task was unloaded.
            logger -p 1 "[$$]: The previous scheduled update task was unloaded."
        fi
        return
    fi
    local interval_day="*/${INTERVAL_DAY}" timer_hour="${TIMER_HOUR}" timer_min="${TIMER_MIN}" xmode="0" num="0" suffix_str="s"
    [ "${timer_hour}" = "x" ] && [ "${timer_min}" = "x" ] && xmode="1"
    [ "${timer_hour}" = "x" ] && [ "${timer_min}" != "x" ] && xmode="2"
    [ "${timer_hour}" != "x" ] && [ "${timer_min}" = "x" ] && xmode="3"
    [ "${timer_hour}" = "x" ] && timer_hour="$( date +"%H" | sed 's/^[0]\([0-9]\)$/\1/g' )"
    [ "${timer_min}" = "x" ] && timer_min="$( date +"%M" | sed 's/^[0]\([0-9]\)$/\1/g' )"
    num="$(  crontab -l 2> /dev/null | grep -c "^[^#]*${PROJECT_ID}" )"
    if [ "${num}" = "1" ] \
        && ! crontab -l 2> /dev/null | awk -v xm="${xmode}" '!/^[[:space:]]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {
            if (xm == "0" && $1 == "'"${timer_min}"'" && $2 == "'"${timer_hour}"'" && $3 == "'"${interval_day}"'" && $4 == "*" && $5 == "*") exit 1
            if (xm == "1" && $3 == "'"${interval_day}"'" && $4 == "*" && $5 == "*") exit 1
            if (xm == "2" && $1 == "'"${timer_min}"'" && $3 == "'"${interval_day}"'" && $4 == "*" && $5 == "*") exit 1
            if (xm == "3" && $2 == "'"${timer_hour}"'" && $3 == "'"${interval_day}"'" && $4 == "*" && $5 == "*") exit 1
        }'; then
        timer_min="$( crontab -l 2> /dev/null | awk '!/^[[:space:]]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {print $1}' | sed 's/^[0-9]$/0&/g' )"
        timer_hour="$( crontab -l 2> /dev/null | awk '!/^[[:space:]]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {print $2}' )"
        interval_day="$( crontab -l 2> /dev/null | awk '!/^[[:space:]]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {print $3}' | cut -d '/' -f2 )"
        [ "${interval_day}" = "1" ] && suffix_str=""
        echo "$(lzdate)" [$$]: "  Update ISP Data: ${timer_hour}:${timer_min} Every ${interval_day} day${suffix_str}"
        echo "$(lzdate) ${MY_LINE}"
        echo "$(lzdate)" [$$]: The scheduled update task has been loaded.
        logger -p 1 "[$$]:   Update ISP Data: ${timer_hour}:${timer_min} Every ${interval_day} day${suffix_str}"
        logger -p 1 "${MY_LINE}"
        logger -p 1 "[$$]: The scheduled update task has been loaded."
        return
    fi
    [ "${num}" != "0" ] && sed -i "/^[^#]*${PROJECT_ID}/d" "${CRONTABS_ROOT_FILENAME}" > /dev/null 2>&1
    sed -i "1i ${timer_min} ${timer_hour} ${interval_day} * * /bin/sh ${PATH_LZ}/${PROJECT_FILENAME} update > /dev/null 2>&1 # Added by LZ" "${CRONTABS_ROOT_FILENAME}" > /dev/null 2>&1
    if ! crontab -l 2> /dev/null | grep -q "^[^#]*${PROJECT_ID}"; then
        echo "${timer_min} ${timer_hour} ${interval_day} * * /bin/sh ${PATH_LZ}/${PROJECT_FILENAME} update > /dev/null 2>&1 # Added by LZ" >> "${CRONTABS_ROOT_FILENAME}" 2> /dev/null
    fi
    timer_min="$( crontab -l 2> /dev/null | awk '!/^[[:space:]]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {print $1}' | sed 's/^[0-9]$/0&/g' )"
    timer_hour="$( crontab -l 2> /dev/null | awk '!/^[[:space:]]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {print $2}' )"
    interval_day="$( crontab -l 2> /dev/null | awk '!/^[[:space:]]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {print $3}' | cut -d '/' -f2 )"
    [ "${interval_day}" = "1" ] && suffix_str=""
    echo "$(lzdate)" [$$]: "  Update ISP Data: ${timer_hour}:${timer_min} Every ${interval_day} day${suffix_str}"
    echo "$(lzdate) ${MY_LINE}"
    echo "$(lzdate)" [$$]: The scheduled update task was loaded successfully.
    logger -p 1 "[$$]:   Update ISP Data: ${timer_hour}:${timer_min} Every ${interval_day} day${suffix_str}"
    logger -p 1 "${MY_LINE}"
    logger -p 1 "[$$]: The scheduled update task was loaded successfully."
}

unload_update_task() {
    ! crontab -l 2> /dev/null | grep -q "^[^#]*${PROJECT_ID}" && {
        sed -i "/^[^#]*${PROJECT_ID}/d" "${CRONTABS_ROOT_FILENAME}" > /dev/null 2>&1
        echo "$(lzdate)" [$$]: No scheduled update task.
        logger -p 1 "[$$]: No scheduled update task."
        return
    }
    sed -i "/^[^#]*${PROJECT_ID}/d" "${CRONTABS_ROOT_FILENAME}" > /dev/null 2>&1
    echo "$(lzdate)" [$$]: Successfully unloaded the scheduled update task.
    logger -p 1 "[$$]: Successfully unloaded the scheduled update task."
}

load_system_boot() {
    while true
    do
        [ "$( grep -c "^[^#]*${PATH_LZ}/${PROJECT_FILENAME}" "${BOOT_START_FILENAME}" 2> /dev/null )" = "1" ] && {
            echo "$(lzdate)" [$$]: The system boot process has been added.
            logger -p 1 "[$$]: The system boot process has been added."
            break
        }
        sed -i "/^[^#]*${PROJECT_ID}/d" "${BOOT_START_FILENAME}" > /dev/null 2>&1
        sed -i "1i /bin/sh ${PATH_LZ}/${PROJECT_FILENAME} update # Added by LZ" "${BOOT_START_FILENAME}" > /dev/null 2>&1
        grep -q "^[^#]*${PATH_LZ}/${PROJECT_FILENAME}" "${BOOT_START_FILENAME}" 2> /dev/null && {
            echo "$(lzdate)" [$$]: Successfully joined the system boot process.
            logger -p 1 "[$$]: Successfully joined the system boot process."
            break
        }
        sed -i "/^[[:space:]]*exit[[:space:]]*[0]/d" "${BOOT_START_FILENAME}" > /dev/null 2>&1
        echo -e "/bin/sh ${PATH_LZ}/${PROJECT_FILENAME} update # Added by LZ\nexit 0" >> "${BOOT_START_FILENAME}" 2> /dev/null
        echo "$(lzdate)" [$$]: Successfully joined the system boot process.
        logger -p 1 "[$$]: Successfully joined the system boot process."
    done
    echo "$(lzdate) ${MY_LINE}"
    echo "$(lzdate)" [$$]: All ISP data of the policy route have been loaded.
    logger -p 1 "${MY_LINE}"
    logger -p 1 "[$$]: All ISP data of the policy route have been loaded."
}

unload_system_boot() {
    ! grep -q "^[^#]*${PROJECT_ID}" "${BOOT_START_FILENAME}" 2> /dev/null && {
        echo "$(lzdate)" [$$]: No bootstrap entry.
        logger -p 1 "[$$]: No bootstrap entry."
        return
    }
    sed -i "/^[^#]*${PROJECT_ID}/d" "${BOOT_START_FILENAME}" > /dev/null 2>&1
    echo "$(lzdate)" [$$]: The bootstrap was successfully unloaded.
    logger -p 1 "[$$]: The bootstrap was successfully unloaded."
}

command_parsing() {
    [ "${HAMMER}" != "${UNLOAD}" ] && ! check_suport_evn && return "1"
    [ "${PARAM_TOTAL}" = "0" ] && return "0"
    if [ "${HAMMER}" = "${UPDATE}" ]; then
        update_isp_data && return "0"
        return "1"
    elif [ "${HAMMER}" = "${UNLOAD}" ]; then
        unload_update_task
        unload_system_boot
        delete_ipsets
        delete_custom_rule
        rm -f "${CUSTOM_IPSETS_TMP_LST_FILENAME}" > /dev/null 2>&1
        echo "$(lzdate)" [$$]: All ISP data have been unloaded.
        logger -p 1 "[$$]: All ISP data have been unloaded."
        return "1"
    fi
    echo "$(lzdate)" [$$]: Oh, you\'re using the wrong command.
    logger -p 1 "[$$]: Oh, you're using the wrong command."
    return "1"
}

print_header() {
    echo "$(lzdate)" [$$]:
    echo "$(lzdate) ${MY_LINE}"
    echo "$(lzdate)" [$$]: LZ RULES "${LZ_VERSION}" script commands start...
    echo "$(lzdate)" [$$]: By LZ \(larsonzhang@gmail.com\)
    echo "$(lzdate) ${MY_LINE}"
    echo "$(lzdate)" [$$]: Location: "${PATH_LZ}"
    echo "$(lzdate) ${MY_LINE}"

    logger -p 1 "[$$]: "
    logger -p 1 "${MY_LINE}"
    logger -p 1 "[$$]: LZ RULES ${LZ_VERSION} script commands start..."
    logger -p 1 "[$$]: By LZ (larsonzhang@gmail.com)"
    logger -p 1 "${MY_LINE}"
    logger -p 1 "[$$]: Location: ${PATH_LZ}"
    logger -p 1 "${MY_LINE}"
}

print_tail() {
    echo "$(lzdate) ${MY_LINE}"
    echo "$(lzdate)" [$$]: LZ RULES "${LZ_VERSION}" script commands executed!
    echo "$(lzdate)" [$$]:

    logger -p 1 "${MY_LINE}"
    logger -p 1 "[$$]: LZ RULES ${LZ_VERSION} script commands executed!"
    logger -p 1 "[$$]: "
}


# ---------------------执行代码---------------------

print_header

while true
do
    command_parsing || break
    ! check_isp_data && { ! update_isp_data && break; }
    cleaning_user_data
    delete_custom_rule
    get_wan_dev_list
    add_wan_address_rule
    delete_ipsets
    create_ipsets
    load_ipsets
    load_update_task
    load_system_boot
    break
done

print_tail

# END
