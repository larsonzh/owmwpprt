#!/bin/sh
# lzrules.sh v2.0.4
# By LZ 妙妙呜 (larsonzhang@gmail.com)

# LZ RULES script for OpenWrt based router

# 脚本命令 (假设当前在lzrules目录)
# 加载规则数据         ./lzrules.sh
# 更新数据文件         ./lzrules.sh update
# 卸载运行数据         ./lzrules.sh unload

# OpenWrt多WAN口策略路由分流脚本

# 使用说明：
# 1.脚本作为mwan3的配套软件使用，请提前到OpenWrt中的“Software”界面内搜索并下载安装如下软件包：
#    mwan3
#    luci-app-mwan3
#    luci-i18n-mwan3-zh-cn
#    iptables-nft
#    ip6tables-nft
#    wget-ssl
#    curl
#    dnsmasq-full
#   注：dnsmasq-full安装前需卸载删除原有的dnsmasq软件包。
# 2.脚本中的WAN口对应实际的物理接口，每个WAN口根据用户在network文件中接口设置，可能包含IPv4和IPv6协议的两个
#   虚拟接口，按照OpenWrt“网络-MultiWAN管理器-接口”配置界面里的IPv4/6协议接口设定顺序排列。
# 3.脚本已涵盖中国地区所有运营商IPv4/IPv6目标网段，访问国外的流量出口在“MultiWAN管理器”中配置出口策略规则。
# 4.在脚本中配置完流量出口后，需在“MultiWAN管理器-规则”界面内，将WAN口数据集合名称（如：ISPIP_SET_0），填
#   入相应WAN口策略规则条目中的“IP配置”字段内。填写时，在下拉框中选择“自定义”，在输入框中书写完毕后按回车键，
#   即可完成数据集合名称的输入。卸载脚本时，请在下拉框中选择“--请选择--”项，然后按页面中的“保存”，最后在“规
#   则”界面中“保存并应用”，就可以解除该WAN口数据集合与相应规则的绑定关系。

# BEGIN

# shellcheck disable=SC2034  # Unused variables left for readability


# ----------------用户运行策略自定义区----------------

# 中国电信IPv4/IPv6目标网段流量出口（网段数据文件：chinatelecom_cidr.txt/chinatelecom_ipv6.txt）
# 0--第一WAN口；1--第二WAN口；···；7--第八WAN口；8--负载均衡；9--禁用；取值范围：0~9
# 缺省：IPv4流量出口--第一WAN口（0）；IPv6流量出口--禁用（9）。
ISP_0_WAN_PORT=0
ISP_0_WAN_PORT_V6=9

# 中国联通/网通IPv4/IPv6目标网段流量出口（网段数据文件：unicom_cnc_cidr.txt/unicom_cnc_ipv6.txt）
# 0--第一WAN口；1--第二WAN口；···；7--第八WAN口；8--负载均衡；9--禁用；取值范围：0~9
# 缺省：IPv4流量出口--第一WAN口（0）；IPv6流量出口--禁用（9）。
ISP_1_WAN_PORT=0
ISP_1_WAN_PORT_V6=9

# 中国移动IPv4/IPv6目标网段流量出口（网段数据文件：cmcc_cidr.txt/cmcc_ipv6.txt）
# 0--第一WAN口；1--第二WAN口；···；7--第八WAN口；8--负载均衡；9--禁用；取值范围：0~9
# 缺省：IPv4流量出口--第二WAN口（1）；IPv6流量出口--禁用（9）。
ISP_2_WAN_PORT=1
ISP_2_WAN_PORT_V6=9

# 中国铁通IPv4/IPv6目标网段流量出口（网段数据文件：crtc_cidr.txt/crtc_ipv6.txt）
# 0--第一WAN口；1--第二WAN口；···；7--第八WAN口；8--负载均衡；9--禁用；取值范围：0~9
# 缺省：IPv4流量出口--第二WAN口（1）；IPv6流量出口--禁用（9）。
ISP_3_WAN_PORT=1
ISP_3_WAN_PORT_V6=9

# 中国教育网IPv4/IPv6目标网段流量出口（网段数据文件：cernet_cidr.txt/cernet_ipv6.txt）
# 0--第一WAN口；1--第二WAN口；···；7--第八WAN口；8--负载均衡；9--禁用；取值范围：0~9
# 缺省：IPv4流量出口--第二WAN口（1）；IPv6流量出口--禁用（9）。
ISP_4_WAN_PORT=1
ISP_4_WAN_PORT_V6=9

# 长城宽带/鹏博士IPv4/IPv6目标网段流量出口（网段数据文件：gwbn_cidr.txt/gwbn_ipv6.txt）
# 0--第一WAN口；1--第二WAN口；···；7--第八WAN口；8--负载均衡；9--禁用；取值范围：0~9
# 缺省：IPv4流量出口--第二WAN口（1）；IPv6流量出口--禁用（9）。
ISP_5_WAN_PORT=1
ISP_5_WAN_PORT_V6=9

# 中国大陆其他运营商IPv4/IPv6目标网段流量出口（网段数据文件：othernet_cidr.txt/othernet_ipv6.txt）
# 0--第一WAN口；1--第二WAN口；···；7--第八WAN口；8--负载均衡；9--禁用；取值范围：0~9
# 缺省：IPv4流量出口--第一WAN口（0）；IPv6流量出口--禁用（9）。
ISP_6_WAN_PORT=0
ISP_6_WAN_PORT_V6=9

# 香港地区运营商IPv4/IPv6目标网段流量出口（网段数据文件：hk_cidr.txt/hk_ipv6.txt）
# 0--第一WAN口；1--第二WAN口；···；7--第八WAN口；8--负载均衡；9--禁用；取值范围：0~9
# 缺省：IPv4流量出口--第一WAN口（0）；IPv6流量出口--禁用（9）。
ISP_7_WAN_PORT=0
ISP_7_WAN_PORT_V6=9

# 澳门地区运营商IPv4/IPv6目标网段流量出口（网段数据文件：mo_cidr.txt/mo_ipv6.txt）
# 0--第一WAN口；1--第二WAN口；···；7--第八WAN口；8--负载均衡；9--禁用；取值范围：0~9
# 缺省：IPv4流量出口--第一WAN口（0）；IPv6流量出口--禁用（9）。
ISP_8_WAN_PORT=0
ISP_8_WAN_PORT_V6=9

# 台湾地区运营商IPv4/IPv6目标网段流量出口（网段数据文件：tw_cidr.txt/tw_ipv6.txt）
# 0--第一WAN口；1--第二WAN口；···；7--第八WAN口；8--负载均衡；9--禁用；取值范围：0~9
# 缺省：IPv4流量出口--第一WAN口（0）；IPv6流量出口--禁用（9）。
ISP_9_WAN_PORT=0
ISP_9_WAN_PORT_V6=9

# 定时更新ISP网络运营商CIDR网段数据时间参数定义
# 建议在当天1:30后执行定时更新。
# 缺省为每隔3天，小时数和分钟数由系统指定。
INTERVAL_DAY=3  # 间隔天数（1~31）：取值"3"表示每隔3天；取值"0"表示禁用定时更新。
TIMER_HOUR=x    # 时间小时数（0~23，x表示由系统指定）；取值"3"表示更新当天的凌晨3点。
TIMER_MIN=x     # 时间分钟数（0~59，x表示由系统指定）；取值"18"表示更新当天的凌晨3点18分。
# 网段数据变更不很频繁，更新间隔时间不要太密集，有助于降低远程下载服务器的负荷压力。
# 脚本运行期间，修改定时设置、路由器重启，或手工停止脚本运行后再次重启，会导致定时更新时间重新开始计数。

# 定时更新ISP网络运营商CIDR网段数据失败后自动重试次数
# 0--不重试；>0--重试次数；取值范围：0~99
# 缺省为重试5次。
RETRY_NUM=5
# 若自动重试后经常下载失败，建议自行前往 https://ispip.clang.cn/ 网站手工下载获取与上述10个网络运营商网
# 段数据文件同名的最新CIDR网段数据，下载后直接粘贴覆盖 /etc/lzrules/data/ 目录内同名数据文件，重启脚本即
# 刻生效。

# 完成出口设定后，需将WAN口的网段数据集合名称（例如：ISPIP_SET_0）填入“MultiWAN管理器”内相应WAN口策略规
# 则条目中的“IP配置”字段内，形成绑定关系，即可最终通过OpenWrt内的mwan3软件完成多WAN口流量的策略路由。脚本
# 的主要作用就是为mwan3生成可供其多个WAN口通道选择使用的目标流量网段数据集合，从而实现更复杂的业务策略。

# WAN口国内IPv4网段数据集合名称
# 从上往下按mwan3设置中第一WAN口、第二WAN口至第八WAN口的顺序排列，每个WAN口一个，可最多对应八个物理WAN口的使用。
ISPIP_SET_0="ISPIP_SET_0"
ISPIP_SET_1="ISPIP_SET_1"
ISPIP_SET_2="ISPIP_SET_2"
ISPIP_SET_3="ISPIP_SET_3"
ISPIP_SET_4="ISPIP_SET_4"
ISPIP_SET_5="ISPIP_SET_5"
ISPIP_SET_6="ISPIP_SET_6"
ISPIP_SET_7="ISPIP_SET_7"

# WAN口国内IPv6网段数据集合名称
# 从上往下按mwan3设置中第一WAN口、第二WAN口至第八WAN口的顺序排列，每个WAN口一个，可最多对应八个物理WAN口的使用。
ISPIP_V6_SET_0="ISPIP_V6_SET_0"
ISPIP_V6_SET_1="ISPIP_V6_SET_1"
ISPIP_V6_SET_2="ISPIP_V6_SET_2"
ISPIP_V6_SET_3="ISPIP_V6_SET_3"
ISPIP_V6_SET_4="ISPIP_V6_SET_4"
ISPIP_V6_SET_5="ISPIP_V6_SET_5"
ISPIP_V6_SET_6="ISPIP_V6_SET_6"
ISPIP_V6_SET_7="ISPIP_V6_SET_7"

# 多WAN口IPv4流量负载均衡数据集合名称
ISPIP_SET_B="ISPIP_SET_B"

# 多WAN口IPv6流量负载均衡数据集合名称
ISPIP_V6_SET_B="ISPIP_V6_SET_B"

# 用户自定义IPv4目标访问网址/网段数据集合列表文件（custom_ipsets_lst.txt）
# 0--启用；1--禁用；取值范围：0~1
# 缺省为禁用（1）。
CUSTOM_IPSETS=1
# 该列表文件位于项目路径内的data目录内，文本文件，名称和路径不可更改。
# 每一行可定义一个网址/网段数据集合，可定义多条，数量不限。数据集合可在mwan3的WAN口流量策略规则设置中使用。
# 格式：
# 数据集合名称="全路径IPv4网址/网段数据文件名"
# 注意：
# 数据集合名称在整个路由器系统中具有唯一性，不能重复，否则会创建失败或影响系统中的其他代码运行；等号前后不能
# 有空格；输入字符为英文半角，且符合Linux变量名称、路径命名、文件命名的规则；全路径文件名要用英文半角双引号
# 括起来。
# 例如：
# MY_IPSET_0="/mypath/my_ip_address_list_0.txt" # 我的第一个网址/网段数据集合
# MY_IPSET_1="/mypath/my_ip_address_list_1.txt"
# 条目起始处加#符号，可忽略该条定义；在每条定义后面加空格，再添加#符号，后面可填写该条目的备注。
# 网址/网段数据文件由用户自己编制和命名，内容格式可参考data目录内的运营是网段数据文件，每行为一个IPv4格式的
# IP地址或CIDR网段，不能是域名形式的网址，可填写多个条目，数量不限。
# 定义完数据集合列表文件和网址/网段数据文件后，需前往OpenWrt“网络-MultiWAN管理器-规则”界面内，为每个网址/
# 网段数据集合按规则优先级添加和设置单独的出口规则，实现所需的流量出口策略。

# 用户自定义IPv6目标访问网址/网段数据集合列表文件（custom_ipv6_ipsets_lst.txt）
# 0--启用；1--禁用；取值范围：0~1
# 缺省为禁用（1）。
CUSTOM_V6_IPSETS=1
# 该列表文件位于项目路径内的data目录内，文本文件，名称和路径不可更改。
# 每一行可定义一个网址/网段数据集合，可定义多条，数量不限。数据集合可在mwan3的WAN口流量策略规则设置中使用。
# 格式：
# 数据集合名称="全路径IPv6网址/网段数据文件名"
# 注意：
# 数据集合名称在整个路由器系统中具有唯一性，不能重复，否则会创建失败或影响系统中的其他代码运行；等号前后不能
# 有空格；输入字符为英文半角，且符合Linux变量名称、路径命名、文件命名的规则；全路径文件名要用英文半角双引号
# 括起来。
# 例如：
# MY_V6_IPSET_0="/mypath/my_ipv6_address_list_0.txt" # 我的第一个IPv6网址/网段数据集合
# MY_V6_IPSET_1="/mypath/my_ipv6_address_list_1.txt"
# 条目起始处加#符号，可忽略该条定义；在每条定义后面加空格，再添加#符号，后面可填写该条目的备注。
# 网址/网段数据文件由用户自己编制和命名，内容格式可参考data目录内的运营是网段数据文件，每行为一个IPv6格式的
# IP地址或网段，不能是域名形式的网址，可填写多个条目，数量不限。
# 定义完数据集合列表文件和网址/网段数据文件后，需前往OpenWrt“网络-MultiWAN管理器-规则”界面内，为每个网址/
# 网段数据集合按规则优先级添加和设置单独的出口规则，实现所需的流量出口策略。

# 用户自定义目标访问域名IPv4数据集合列表文件（dname_ipsets_lst.txt）
# 0--启用；1--禁用；取值范围：0~1
# 缺省为禁用（1）。
DNAME_IPSETS=1
# 该列表文件位于项目路径内的data目录内，文本文件，名称和路径不可更改。
# 每一行可定义一个域名数据集合，可定义多个，数量不限。数据集合可在mwan3的WAN口流量策略规则设置中使用。
# 格式：
# 数据集合名称
# 注意：
# 数据集合名称在整个路由器系统中具有唯一性，不能重复，否则会创建失败或影响系统中的其他代码运行；输入字符为英
# 文半角，且符合Linux变量名称命名的规则。
# 例如：
# MY_DOMAIN_NAME_IPSET_0 # 我的第一个域名数据集合
# MY_DOMAIN_NAME_IPSET_1
# 条目起始处加#符号，可忽略该条定义；在每条定义后面加空格，再添加#符号，后面可填写该条目备注。
# 此处仅作为全局变量在系统运行空间中定义和初始化域名数据集合，对域名数据集合进行生命周期管理。
# 定义完成后请前往OpenWrt的“网络-DHCP/DNS-IP集”选项卡中，给数据集合关联所需域名，每个数据集合可包含多个域名，
# 最后在mwan3的WAN口流量策略规则中为每个域名数据集合按规则优先级添加和设置单独的出口规则，实现按所访问的域名
# 分配流量出口的策略。


# ---------------------全局变量---------------------

# WAN口最大支持数量
# 每个IPv4 WAN口对应一个国内网段数据集合
MAX_WAN_PORT="8"

# 国内ISP网络运营商CIDR网段数据文件总数
ISP_TOTAL="10"

# 国内ISP网络运营商IPv4 CIDR网段数据文件名
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

# 国内ISP网络运营商IPv6网段数据文件名
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

# 国内ISP网络运营商名称
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

# 国内ISP网络运营商名称
ISP_V6_NAME_0="CTCC_V6    "
ISP_V6_NAME_1="CUCC/CNC_V6"
ISP_V6_NAME_2="CMCC_V6    "
ISP_V6_NAME_3="CRTC_V6    "
ISP_V6_NAME_4="CERNET_V6  "
ISP_V6_NAME_5="GWBN_V6    "
ISP_V6_NAME_6="OTHER_V6   "
ISP_V6_NAME_7="HONGKONG_V6"
ISP_V6_NAME_8="MACAO_V6   "
ISP_V6_NAME_9="TAIWAN_V6  "

# IPv4 WAN端口设备列表
WAN_DEV_LIST="${WAN_DEV_LIST:-""}"

# IPv6 WAN端口设备列表
WAN_V6_DEV_LIST="${WAN_V6_DEV_LIST:-""}"

# 可用IPv4 WAN口数量
WAN_AVAL_NUM="0"

# 可用IPv6 WAN口数量
WAN_V6_AVAL_NUM="0"

# 用户自定义IPv4目标访问网址/网段数据集合列表
CUSTOM_IPSETS_LST=""

# 用户自定义IPv6目标访问网址/网段数据集合列表
CUSTOM_V6_IPSETS_LST=""

# 用户自定义目标访问域名数据集合列表
DNAME_IPSETS_LST=""

# 版本号
LZ_VERSION=v2.0.4

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

# mwan3配置文件名
MWAN3_FILENAME="/etc/config/mwan3"

# mwan3事件通告文件名
MWAN3_NOTIFY_FILENAME="/etc/mwan3.user"

# 主机dhcp配置文件名
HOST_DHCP_FILENAME="/etc/config/dhcp"

# 更新ISP网络运营商CIDR网段数据文件临时下载目录
PATH_TMP_DATA="${PATH_TMP}/download"

# ISP网络运营商CIDR网段数据文件下载站点URL
UPDATE_ISPIP_DATA_DOWNLOAD_URL="https://ispip.clang.cn"

# ISP网络运营商CIDR网段数据文件URL列表文件名
ISPIP_FILE_URL_LIST="ispip_file_url.lst"

# 公网IPv4地址查询网站域名
PIPDN="whatismyip.akamai.com"

# 用户自定义IPv4网址/网段数据集合列表文件名
CUSTOM_IPSETS_LST_FILENAME="${PATH_DATA}/custom_ipsets_lst.txt"

# 用户自定义IPv6网址/网段数据集合列表文件名
CUSTOM_V6_IPSETS_LST_FILENAME="${PATH_DATA}/custom_ipv6_ipsets_lst.txt"

# 用户自定义目标访问域名数据集合列表文件名
DNAME_IPSETS_LST_FILENAME="${PATH_DATA}/dname_ipsets_lst.txt"

# 用户自定义数据集合运行列表临时文件名
CUSTOM_IPSETS_TMP_LST_FILENAME="${PATH_TMP}/custom_ipsets_tmp.lst"

# IPv4地址正则表达式
regex_v4='((25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9])[\.]){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9])([\/]([1-9]|[1-2][0-9]|3[0-2]))?'

# IPv6地址正则表达式
regex_v6="(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:([0-9a-fA-F]{1,4})|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{1,4}){0,4}%[0-9a-zA-Z]+|::(ffff(:0{1,4})?:)?${regex_v4%"([\/]("*}|([0-9a-fA-F]{1,4}:){1,4}:${regex_v4%"([\/]("*})([\/]([1-9]|([1-9]|1[0-1])[0-9]|12[0-8]))?"

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
        if [ -z "$( opkg list-installed "curl" 2> /dev/null )" ] || ! which curl > /dev/null 2>&1; then
            echo "$(lzdate)" [$$]: Package curl is not installed or corrupt.
            logger -p 1 "[$$]: Package curl is not installed or corrupt."
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
        if [ -z "$( opkg list-installed "dnsmasq-full" 2> /dev/null )" ] || ! which wget > /dev/null 2>&1; then
            echo "$(lzdate)" [$$]: Package dnsmasq-full is not installed or corrupt.
            logger -p 1 "[$$]: Package dnsmasq-full is not installed or corrupt."
            retval="1"
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

get_wan_dev_if() {
    uci show "${MWAN3_FILENAME}" 2> /dev/null \
        | awk -F '=' '$2 == "interface" {print $1}' \
        | awk -F '.' 'NF >= 2 {system("'"uci show ${MWAN3_FILENAME}."'"$2"'".family 2> /dev/null"'");}' \
        | awk -v count=0 -F '.' '$3 ~ "'"\'${1}\'"'" {print $2; count++; if (count >= "'"${MAX_WAN_PORT}"'") exit;}'
}

get_wan_dev_list() {
    local wan_list=""  wan_v6_list=""  wan="" wan_v6="" wan_dev="" num="0"
    local dev_list="$( eval "$( eval "$( uci show "${MWAN3_FILENAME}" 2> /dev/null \
        | awk -F '=' '$2 == "interface" {print $1}' \
        | awk -F '.' 'NF >= 2 {system("'"uci show ${MWAN3_FILENAME}."'"$2".family 2> /dev/null");}' \
        | awk -F '.' '$3 ~ "'"\'ipv4|ipv6\'"'" {print "echo "$2,"'"\\\"\$( uci get \\\"${HOST_NETWORK_FILENAME}."'"$2"'".device\\\" 2> /dev/null )\\\""'";}' )" \
        | awk '{if (NF == 2) print "echo "$2; else print "'"uci get \\\"${HOST_NETWORK_FILENAME}."'"$1"'".ifname\\\" 2> /dev/null"'";}' )" \
        | awk 'NF == 1 && $1 !~ /^@/ && !i[$1]++ {print $1}' \
        | awk -v count=0 'NF > 0 {print $1; count++; if (count >= "'"${MAX_WAN_PORT}"'") exit;}' )"
    num="$( echo "${dev_list}" | wc -l )"
    until [ "${num}" -ge "${MAX_WAN_PORT}" ]
    do
        num="$(( num + 1 ))"
        dev_list="$( echo "${dev_list}" | sed -e "\$a eth${num}X" -e '/^[[:space:]]*$/d' )"
    done
    WAN_DEV_LIST="$( echo "${dev_list}" | awk -v count=0 'NF > 0 {print "wan"count"X",$1; count++;}' )"
    WAN_V6_DEV_LIST="$( echo "${dev_list}" | awk -v count=0 'NF > 0 {print "wan"count"v6X",$1; count++;}' )"
    # wan_list="$( sed -e 's/^[[:space:]]\+//g' -e 's/[[:space:]]\+/ /g' -e 's/[[:space:]]$//g' "${MWAN3_FILENAME}" 2> /dev/null \
    #     | awk -v flag=0 -v port="" '/^config interface/ {flag=1; port=$3; next} /^config/ {flag=0; next} flag && $0 ~ "'"^option family \'ipv4\'"'" {print port}' \
    #     | sed "s/[\']//g" )"
    wan_list="$( get_wan_dev_if "ipv4" )"
    num="0"
    for wan in ${wan_list}
    do
        wan_dev="$( uci get "${HOST_NETWORK_FILENAME}.${wan}.device" 2> /dev/null )"
        if [ -n "${wan_dev}" ]; then
            echo "${wan_dev}" | grep -q '^@' && wan_dev="$( uci get "${HOST_NETWORK_FILENAME}.${wan_dev#*@}.device" 2> /dev/null )"
        else
            wan_dev="$( uci get "${HOST_NETWORK_FILENAME}.${wan}.ifname" 2> /dev/null )"
            echo "${wan_dev}" | grep -q '^@' && wan_dev="$( uci get "${HOST_NETWORK_FILENAME}.${wan_dev#*@}.ifname" 2> /dev/null )"
        fi
        [ -n "${wan_dev}" ] && WAN_DEV_LIST="$( echo "${WAN_DEV_LIST}" | sed -e "s/^[[:alnum:]]\+[[:space:]]\(${wan_dev}\)$/${wan} \1/" )"
        num="$(( num + 1 ))"
    done
    WAN_AVAL_NUM="${num}"
    wan_v6_list="$( get_wan_dev_if "ipv6" )"
    num="0"
    for wan_v6 in ${wan_v6_list}
    do
        wan_dev="$( uci get "${HOST_NETWORK_FILENAME}.${wan_v6}.device" 2> /dev/null )"
        if [ -n "${wan_dev}" ]; then
            echo "${wan_dev}" | grep -q '^@' && wan_dev="$( uci get "${HOST_NETWORK_FILENAME}.${wan_dev#*@}.device" 2> /dev/null )"
        else
            wan_dev="$( uci get "${HOST_NETWORK_FILENAME}.${wan_v6}.ifname" 2> /dev/null )"
            echo "${wan_dev}" | grep -q '^@' && wan_dev="$( uci get "${HOST_NETWORK_FILENAME}.${wan_dev#*@}.ifname" 2> /dev/null )"
        fi
        [ -n "${wan_dev}" ] && WAN_V6_DEV_LIST="$( echo "${WAN_V6_DEV_LIST}" | sed -e "s/^[[:alnum:]]\+[[:space:]]\(${wan_dev}\)$/${wan_v6} \1/" )"
        num="$(( num + 1 ))"
    done
    WAN_V6_AVAL_NUM="${num}"
}

get_wan_if() {
    local wan="${1}"
    [ -n "${WAN_DEV_LIST}" ] && wan="$( echo "${WAN_DEV_LIST}" | awk '$2 == "'"${wan}"'" {print $1; exit}' )"
    [ -z "${wan}" ] && wan="${1}"
    echo "${wan}"
}

get_wan_if_v6() {
    local wan="${1}"
    [ -n "${WAN_DEV_LIST}" ] && wan="$( echo "${WAN_V6_DEV_LIST}" | awk '$2 == "'"${wan}"'" {print $1; exit}' )"
    [ -z "${wan}" ] && wan="${1}"
    echo "${wan}"
}

get_wan_name() {
    local index="${1}" wan="" 
    index="$(( index + 1 ))"
    [ -n "${WAN_DEV_LIST}" ] && wan="$( echo "${WAN_DEV_LIST}" | awk 'NR == "'"${index}"'" {print $1}' )"
    echo "${wan}"
}

get_wan_name_v6() {
    local index="${1}" wan="" 
    index="$(( index + 1 ))"
    [ -n "${WAN_V6_DEV_LIST}" ] && wan="$( echo "${WAN_V6_DEV_LIST}" | awk 'NR == "'"${index}"'" {print $1}' )"
    echo "${wan}"
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
        NF == "1" && !i[$1]++ {print fix_cidr($1);}' \
        | awk 'NF == "1" && !i[$1]++ {print $1}'
}

print_ipv6_address_list() {
    sed -e 's/^[[:space:]]\+//g' -e 's/[[:space:]#].*$//g' \
        -e 's/\(^\|[\:\/\%]\)[0]\+\([[:digit:]]\)/\1\2/g' \
        -e "/^$( echo "${regex_v6}" | sed 's/[(){}|+?]/\\&/g' )$/!d" \
        -e 's/\/128//g' "${1}" \
        | awk 'NF == "1" && !i[$1]++ {print tolower($1)}'
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
    print_ipv4_address_list "${1}" | awk 'NF >= "1" {print "'"-! del ${2} "'"$1"'"\n-! add ${2} "'"$1} END{print "COMMIT"}' | ipset restore > /dev/null 2>&1
}

get_ipv4_data_file_item_total() {
    local retval="0"
    [ -s "${1}" ] && {
        retval="$( print_ipv4_address_list "${1}" 2> /dev/null \
            | awk -v count="0" 'NF >= "1" {count++} END{print count}' )"
    }
    echo "${retval}"
}

add_ipv6_net_address_sets() {
    if [ ! -s "${1}" ] || [ -z "${2}" ]; then return; fi;
    ipset -q create "${2}" hash:net family ipv6 maxelem 4294967295 #--hashsize 1024 mexleme 65536
    print_ipv6_address_list "${1}" | awk 'NF >= "1" {print "'"-! del ${2} "'"$1"'"\n-! add ${2} "'"$1} END{print "COMMIT"}' | ipset restore > /dev/null 2>&1
}

get_ipv6_data_file_item_total() {
    local retval="0"
    [ -s "${1}" ] && {
        retval="$( print_ipv6_address_list "${1}" 2> /dev/null \
            | awk -v count="0" 'NF >= "1" {count++} END{print count}' )"
    }
    echo "${retval}"
}

get_wan_list() {
    local wan_list="$( uci show "${MWAN3_FILENAME}" 2> /dev/null \
            | awk -F '.' '$0 ~ "'"ipset=\'${1}\'"'" && $2 != "" {system("'"uci get ${MWAN3_FILENAME}."'"$2".use_policy 2> /dev/null")}' \
            | awk '$1 != "" {system("'"uci get ${MWAN3_FILENAME}."'"$1".use_member 2> /dev/null")}' \
            | sed -e 's/[[:space:]]\+/\n/g'  -e '/^[[:space:]]*$/d' \
            | awk '$1 != "" {system("'"uci get ${MWAN3_FILENAME}."'"$1".interface  2> /dev/null")}' )"
    echo "${wan_list}"
}

get_ipset_total() {
    ipset -q list "${1}" | grep -Ec "^${regex_v4}$"
}

get_ipv6_ipset_total() {
    ipset -q list "${1}" | grep -Ec "^${regex_v6}$"
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
            wan="$( get_wan_list "${name}" )"
            if [ -n "${wan}" ]; then
                for wan in ${wan}
                do
                    printf "%s %-12s %-13s\t%s\n" "$(lzdate) [$$]:  " "${wan}" "${name}" "${num}"
                    logger -p 1 "$( printf "%s %-6s\t%-16s%s\n" "[$$]:  " "${wan}" "${name}" "${num}" )"
                done
            else
                wan="$( get_wan_name "${index}" )"
                printf "%s %-12s %-13s\t%s\n" "$(lzdate) [$$]:  " "${wan}" "${name}" "${num}"
                logger -p 1 "$( printf "%s %-6s\t%-16s%s\n" "[$$]:  " "${wan}" "${name}" "${num}" )"
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
        wan="$( get_wan_list "${ISPIP_SET_B}" )"
        if [ -n "${wan}" ]; then
            for wan in ${wan}
            do
                printf "%s %-12s %-13s\t%s\n" "$(lzdate) [$$]:  " "${wan}" "${ISPIP_SET_B}" "${num}"
                logger -p 1 "$( printf "%s %-6s\t%-16s%s\n" "[$$]:  " "${wan}" "${ISPIP_SET_B}" "${num}" )"
            done
        else
            wan="LBX"
            printf "%s %-12s %-13s\t%s\n" "$(lzdate) [$$]:  " "${wan}" "${ISPIP_SET_B}" "${num}"
            logger -p 1 "$( printf "%s %-6s\t%-16s%s\n" "[$$]:  " "${wan}" "${ISPIP_SET_B}" "${num}" )"
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
            wan="$( get_wan_list "${name%=*}" )"
            if [ -n "${wan}" ]; then
                for wan in ${wan}
                do
                    printf "%s %-12s %-13s\t%s\n" "$(lzdate) [$$]:  " "${wan}" "${name%=*}" "${num}"
                    logger -p 1 "$( printf "%s %-6s\t%-16s%s\n" "[$$]:  " "${wan}" "${name%=*}" "${num}" )"
                done
            else
                wan="wanX"
                printf "%s %-12s %-13s\t%s\n" "$(lzdate) [$$]:  " "${wan}" "${name%=*}" "${num}"
                logger -p 1 "$( printf "%s %-6s\t%-16s%s\n" "[$$]:  " "${wan}" "${name%=*}" "${num}" )"
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
            wan="$( get_wan_list "${name}" )"
            if [ -n "${wan}" ]; then
                for wan in ${wan}
                do
                    printf "%s %-12s %-13s\t%s%s\n" "$(lzdate) [$$]:  " "${wan}" "${name}" "${num}" "(${buf})"
                    logger -p 1 "$( printf "%s %-6s\t%-16s%s%s\n" "[$$]:  " "${wan}" "${name}" "${num}" "(${buf})" )"
                done
            else
                wan="wanX"
                printf "%s %-12s %-13s\t%s%s\n" "$(lzdate) [$$]:  " "${wan}" "${name}" "${num}" "(${buf})"
                logger -p 1 "$( printf "%s %-6s\t%-16s%s%s\n" "[$$]:  " "${wan}" "${name}" "${num}" "(${buf})" )"
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
            wan="$( get_wan_list "${name}" )"
            if [ -n "${wan}" ]; then
                for wan in ${wan}
                do
                    printf "%s %-12s %-13s\t%s\n" "$(lzdate) [$$]:  " "${wan}" "${name}" "${num}"
                    logger -p 1 "$( printf "%s %-6s\t%-16s%s\n" "[$$]:  " "${wan}" "${name}" "${num}" )"
                done
            else
                wan="$( get_wan_name_v6 "${index}" )"
                printf "%s %-12s %-13s\t%s\n" "$(lzdate) [$$]:  " "${wan}" "${name}" "${num}"
                logger -p 1 "$( printf "%s %-6s\t%-16s%s\n" "[$$]:  " "${wan}" "${name}" "${num}" )"
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
        wan="$( get_wan_list "${ISPIP_V6_SET_B}" )"
        if [ -n "${wan}" ]; then
            for wan in ${wan}
            do
                printf "%s %-12s %-13s\t%s\n" "$(lzdate) [$$]:  " "${wan}" "${ISPIP_V6_SET_B}" "${num}"
                logger -p 1 "$( printf "%s %-6s\t%-16s%s\n" "[$$]:  " "${wan}" "${ISPIP_V6_SET_B}" "${num}" )"
            done
        else
            wan="LBX"
            printf "%s %-12s %-13s\t%s\n" "$(lzdate) [$$]:  " "${wan}" "${ISPIP_V6_SET_B}" "${num}"
            logger -p 1 "$( printf "%s %-6s\t%-16s%s\n" "[$$]:  " "${wan}" "${ISPIP_V6_SET_B}" "${num}" )"
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
            wan="$( get_wan_list "${name%=*}" )"
            if [ -n "${wan}" ]; then
                for wan in ${wan}
                do
                    printf "%s %-12s %-13s\t%s\n" "$(lzdate) [$$]:  " "${wan}" "${name%=*}" "${num}"
                    logger -p 1 "$( printf "%s %-6s\t%-16s%s\n" "[$$]:  " "${wan}" "${name%=*}" "${num}" )"
                done
            else
                wan="wanX"
                printf "%s %-12s %-13s\t%s\n" "$(lzdate) [$$]:  " "${wan}" "${name%=*}" "${num}"
                logger -p 1 "$( printf "%s %-6s\t%-16s%s\n" "[$$]:  " "${wan}" "${name%=*}" "${num}" )"
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
    local ifn="$( ip route show 2> /dev/null | awk '/default/ {if ($5 != "") print $5}' )" ifx="" item="" lined="0"
    for ifn in ${ifn}
    do
        [ "${lined}" = "0" ] && {
            lined="1"
            echo "$(lzdate) ${MY_LINE}"
            logger -p 1 "${MY_LINE}"
        }
        ifx="$( get_wan_if "${ifn}" )"
        eval "$( ip -4 -o address show dev "${ifn}" 2> /dev/null \
            | awk 'NF != "0" {
                ifa=$4;
                psn=index(ifa, "/");
                if (psn > 0) ifa=substr(ifa, 1, psn-1);
                if (index($2, "pppoe") > 0)
                    print $2,ifa,system("curl -s --connect-timeout 20 --interface "$2"'" -w 'OpenWrt' ${PIPDN}"'"" 2> /dev/null");
                else
                    print $2,ifa,system("curl -s --connect-timeout 20 --interface "ifa"'" -w 'OpenWrt' ${PIPDN}"'"" 2> /dev/null");
            }' \
            | awk -F 'OpenWrt' '{print $1}' \
            | awk 'NF >= "2" {
                print "echo "$1" "$2" \"\$( get_isp_name \""$3"\" )\" "$3;
            }' )" \
            | awk 'NF >= "2" {
                wanip="No Public IP";
                if ($4 != "") {wanip=$4; isp=$3;}
                else isp="";
                strbuf=sprintf("%s   %-8s %-12s  %-12s  %s","'"[$$]:"'","'"${ifx}"'",$2,wanip,isp);
                printf("%s %s\n","'"$(lzdate)"'",strbuf);
                system("logger -p 1 \""strbuf"\"");
            }'
    done
    lined="0"
    local strbuf="" count="0"
    ifn="$( echo "${WAN_V6_DEV_LIST}" | awk '$1 !~ /X$/ && $2 !~ /X$/ {print $2}' )"
    for ifn in ${ifn}
    do
        ifx="$( get_wan_if_v6 "${ifn}" )"
        item="$( ip -6 -o address show dev "${ifn}" 2> /dev/null \
            | awk 'NF != "0" {
                ifa=$4;
                psn=index(ifa, "/");
                if (psn > 0) ifa=substr(ifa, 1, psn-1);
                print ifa;
            }' )"
        count="0"
        for item in ${item}
        do
            if [ "${count}" = "0" ]; then
                strbuf="$( printf "%s %-8s %s  %s\n" "[$$]:  " "${ifx}" "${item}" "$( get_isp_name_v6 "${item}" )" )"
            else
                strbuf="$( printf "%s %-8s %s  %s\n" "[$$]:  " "" "${item}" "$( get_isp_name_v6 "${item}" )" )"
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
            wan="OFF"
        fi
        eval name="\${ISP_NAME_${index}}"
        eval num="\$( get_ipv4_data_file_item_total \"\${PATH_DATA}/\${ISP_DATA_${index}}\" )"
        printf "%s %s\t%s\t\t%s\n" "$(lzdate) [$$]:  " "${name}" "${wan}" "${num}" 
        logger -p 1 "$( printf "%s %-11s\t%-6s\t%s\n" "[$$]:  " "${name}" "${wan}" "${num}" )"
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
            wan="OFF"
        fi
        eval name="\${ISP_V6_NAME_${index}}"
        eval num="\$( get_ipv6_data_file_item_total \"\${PATH_DATA}/\${ISP_V6_DATA_${index}}\" )"
        printf "%s %s\t%s\t\t%s\n" "$(lzdate) [$$]:  " "${name}" "${wan}" "${num}" 
        logger -p 1 "$( printf "%s %-11s\t%-6s\t%s\n" "[$$]:  " "${name}" "${wan}" "${num}" )"
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
        eval "wget -q -nc -c --timeout=20 --random-wait --user-agent=\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.5304.88 Safari/537.36 Edg/108.0.1462.46\" --referer=${UPDATE_ISPIP_DATA_DOWNLOAD_URL} ${COOKIES_STR} --keep-session-cookies --no-check-certificate -P ${PATH_TMP_DATA} -i ${PATH_TMP_DATA}/${ISPIP_FILE_URL_LIST}"
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
    get_wan_dev_list
    delete_ipsets
    create_ipsets
    load_ipsets
    load_update_task
    load_system_boot
    break
done

print_tail

# END
