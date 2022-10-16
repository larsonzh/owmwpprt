#!/bin/sh
# lzrules.sh v1.0.0
# By LZ 妙妙呜 (larsonzhang@gmail.com)

# LZ RULES script for OpenWrt based router

# 脚本命令 (假设当前在lzrules目录)
# 加载规则数据         ./lzrules.sh
# 更新数据文件         ./lzrules.sh update
# 卸载运行数据         ./lzrules.sh unload

# OpenWrt多WAN口策略路由分流脚本

# BEIGIN

# shellcheck disable=SC2034  # Unused variables left for readability


# ----------------用户运行策略自定义区----------------

# 中国电信目标网段流量出口（网段数据文件：chinatelecom_cidr.txt）
# 0--第一WAN口；1--第二WAN口；······；7--第八WAN口；取值范围：0~7
# 缺省为第一WAN口（0）。
ISP_0_WAN_PORT=0

# 中国联通/网通目标网段流量出口（网段数据文件：unicom_cnc_cidr.txt）
# 0--第一WAN口；1--第二WAN口；······；7--第八WAN口；取值范围：0~7
# 缺省为第一WAN口（0）。
ISP_1_WAN_PORT=0

# 中国移动目标网段流量出口（网段数据文件：cmcc_cidr.txt）
# 0--第一WAN口；1--第二WAN口；······；7--第八WAN口；取值范围：0~7
# 缺省为第二WAN口（1）。
# 1：表示对中国移动网段的访问使用第二AN口。
ISP_2_WAN_PORT=1

# 中国铁通目标网段流量出口（网段数据文件：crtc_cidr.txt）
# 0--第一WAN口；1--第二WAN口；······；7--第八WAN口；取值范围：0~7
# 缺省为第二WAN口（1）。
ISP_3_WAN_PORT=1

# 中国教育网目标网段流量出口（网段数据文件：cernet_cidr.txt）
# 0--第一WAN口；1--第二WAN口；······；7--第八WAN口；取值范围：0~7
# 缺省值为第二WAN口（1）。
ISP_4_WAN_PORT=1

# 长城宽带/鹏博士目标网段流量出口（网段数据文件：gwbn_cidr.txt）
# 0--第一WAN口；1--第二WAN口；······；7--第八WAN口；取值范围：0~7
# 缺省为第二WAN口（1）。
ISP_5_WAN_PORT=1

# 中国大陆其他运营商目标网段流量出口（网段数据文件：othernet_cidr.txt）
# 0--第一WAN口；1--第二WAN口；······；7--第八WAN口；取值范围：0~7
# 缺省为第一WAN口（0）。
ISP_6_WAN_PORT=0

# 香港地区运营商目标网段流量出口（网段数据文件：hk_cidr.txt）
# 0--第一WAN口；1--第二WAN口；······；7--第八WAN口；取值范围：0~7
# 缺省为第一WAN口（0）。
ISP_7_WAN_PORT=0

# 澳门地区运营商目标网段流量出口（网段数据文件：mo_cidr.txt）
# 0--第一WAN口；1--第二WAN口；······；7--第八WAN口；取值范围：0~7
# 缺省为第一WAN口（0）。
ISP_8_WAN_PORT=0

# 台湾地区运营商目标网段流量出口（网段数据文件：tw_cidr.txt）
# 0--第一WAN口；1--第二WAN口；······；7--第八WAN口；取值范围：0~7
# 缺省为第一WAN口（0）。
ISP_9_WAN_PORT=0

# 定时更新ISP网络运营商CIDR网段数据时间参数定义
# 建议在当天1:30后执行定时更新。
# 缺省为每隔3天，小时数和分钟数由系统指定。
INTERVAL_DAY=3  ## 间隔天数（1~31）：取值"3"表示每隔3天；取值"0"表示禁用定时更新。
TIMER_HOUR=x    ## 时间小时数（0~23，x表示由系统指定）；取值"3"表示更新当天的凌晨3点。
TIMER_MIN=x     ## 时间分钟数（0~59，x表示由系统指定）；取值"18"表示更新当天的凌晨3点18分。
# 网段数据变更不很频繁，更新间隔时间不要太密集，有助于降低远程下载服务器的负荷压力。
# 脚本运行期间，修改定时设置、路由器重启，或手工停止脚本运行后再次重启，会导致定时更新时间重新开始计数。

# 定时更新ISP网络运营商CIDR网段数据失败后自动重试次数
# 0--不重试；>0--重试次数；取值范围：0~99
# 缺省为重试5次。
RETRY_NUM=5
# 若自动重试后经常下载失败，建议自行前往 https://ispip.clang.cn/ 网站手工下载获取与上述10个网络运营商网段数据
# 文件同名的最新CIDR网段数据，下载后直接粘贴覆盖 /etc/lzrules/data/ 目录内同名数据文件，重启脚本即刻生效。


# ---------------------全局变量---------------------

# WAN口最大支持数量
# 每个IPv4 WAN口对应一个国内网段数据集
MAX_WAN_PORT="8"

# 第一WAN口国内网段数据集名称
ISPIP_SET_0="ISPIP_SET_0"

# 第二WAN口国内网段数据集名称
ISPIP_SET_1="ISPIP_SET_1"

# 第三WAN口国内网段数据集名称
ISPIP_SET_2="ISPIP_SET_2"

# 第四WAN口国内网段数据集名称
ISPIP_SET_3="ISPIP_SET_3"

# 第五WAN口国内网段数据集名称
ISPIP_SET_4="ISPIP_SET_4"

# 第六WAN口国内网段数据集名称
ISPIP_SET_5="ISPIP_SET_5"

# 第七WAN口国内网段数据集名称
ISPIP_SET_6="ISPIP_SET_6"

# 第八WAN口国内网段数据集名称
ISPIP_SET_7="ISPIP_SET_7"

# 国内ISP网络运营商CIDR网段数据文件总数
ISP_TOTAL="10"

# 国内ISP网络运营商CIDR网段数据文件名
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

# 国内ISP网络运营商名称
ISP_NAME_0="CTCC"
ISP_NAME_1="CUCC/CNC"
ISP_NAME_2="CMCC"
ISP_NAME_3="CRTC"
ISP_NAME_4="CERNET"
ISP_NAME_5="GWBN"
ISP_NAME_6="Other"
ISP_NAME_7="Hongkong"
ISP_NAME_8="Macao"
ISP_NAME_9="Taiwan"

# 版本号
LZ_VERSION=v1.0.0

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

# 更新ISP网络运营商CIDR网段数据文件临时下载目录
PATH_TMP_DATA="${PATH_TMP}/download"

# ISP网络运营商CIDR网段数据文件下载站点URL
UPDATE_ISPIP_DATA_DOWNLOAD_URL="https://ispip.clang.cn"

# ISP网络运营商CIDR网段数据文件URL列表文件名
ISPIP_FILE_URL_LIST="ispip_file_url_list.lst"

# 公网IPv4地址查询网站域名
PIPDN="whatismyip.akamai.com"

# 脚本操作命令
HAMMER="$( echo "${1}" | tr '[:A-Z:]' '[:a-z:]' )"
UPDATE="update"
UNLOAD="unload"
PARAM_TOTAL="${#}"

MY_LINE="[$$]: ---------------------------------------------"


# ---------------------函数定义---------------------

lzdate() { eval echo "$( date +"%F %T" )"; }

cleaning_user_data() {
    ! echo "${ISP_0_WAN_PORT}" | grep -q '^[0-7]$' && ISP_0_WAN_PORT="0"
    ! echo "${ISP_1_WAN_PORT}" | grep -q '^[0-7]$' && ISP_1_WAN_PORT="0"
    ! echo "${ISP_2_WAN_PORT}" | grep -q '^[0-7]$' && ISP_2_WAN_PORT="1"
    ! echo "${ISP_3_WAN_PORT}" | grep -q '^[0-7]$' && ISP_3_WAN_PORT="1"
    ! echo "${ISP_4_WAN_PORT}" | grep -q '^[0-7]$' && ISP_4_WAN_PORT="1"
    ! echo "${ISP_5_WAN_PORT}" | grep -q '^[0-7]$' && ISP_5_WAN_PORT="1"
    ! echo "${ISP_6_WAN_PORT}" | grep -q '^[0-7]$' && ISP_6_WAN_PORT="0"
    ! echo "${ISP_7_WAN_PORT}" | grep -q '^[0-7]$' && ISP_7_WAN_PORT="0"
    ! echo "${ISP_8_WAN_PORT}" | grep -q '^[0-7]$' && ISP_8_WAN_PORT="0"
    ! echo "${ISP_9_WAN_PORT}" | grep -q '^[0-7]$' && ISP_9_WAN_PORT="0"
    ! echo "${INTERVAL_DAY}" | grep -qE '^[0-9]$|^[1-2][0-9]$|^[3][0-1]$' && INTERVAL_DAY="3"
    ! echo "${TIMER_HOUR}" | grep -qE '^[0-9]$|^[1][0-9]$|^[2][0-3]$|^[xX]$' && TIMER_HOUR="x"
    [ "${TIMER_HOUR}" = "X" ] && TIMER_HOUR="x"
    ! echo "${TIMER_MIN}" | grep -qE '^[0-9]$|^[1-5][0-9]$|^[xX]$' && TIMER_MIN="x"
    [ "${TIMER_MIN}" = "X" ] && TIMER_MIN="x"
    ! echo "${RETRY_NUM}" | grep -qE '^[0-9]$|^[1-9][0-9]$' && RETRY_NUM="5"
}

get_wan_dev() {
    local wan="${1}"
    if [ -f "${HOST_NETWORK_FILENAME}" ]; then
        wan="$( sed -e 's/^[ ]*//g' -e 's/[ ][ ]*/ /g' -e 's/[ ]$//g' "${HOST_NETWORK_FILENAME}" 2> /dev/null \
            | awk -v flag=0 '$0 == "'"config interface \'${wan}\'"'" {flag=1; next} flag && $0 ~ /option device/ {print $3; exit}' \
            | sed "s/[']//g" )"
        [ -z "${wan}" ] && wan="${1}"
    fi
    echo "${wan}"
}

delete_ipsets() {
    local port="0"
    until [ "${port}" -ge "${MAX_WAN_PORT}" ]
    do
        eval ipset -q flush "\${ISPIP_SET_${port}}" && eval ipset -q destroy "\${ISPIP_SET_${port}}"
        let port++
    done
}

create_ipsets() {
    local port="0"
    until [ "${port}" -ge "${MAX_WAN_PORT}" ]
    do
        if [ -f "${MWAN3_FILENAME}" ] && eval grep -q "^[^#]*\${ISPIP_SET_${port}}" "${MWAN3_FILENAME}" 2> /dev/null; then
            eval ipset -q create "\${ISPIP_SET_${port}}" nethash #--hashsize 65535
            eval ipset -q flush "\${ISPIP_SET_${port}}"
        fi
        let port++
    done
}

add_net_address_sets() {
    if [ ! -f "${1}" ] || [ -z "${2}" ]; then return; fi;
    ipset -q create "${2}" nethash #--hashsize 65535
    sed -e 's/\(^[^#]*\)[#].*$/\1/g' -e '/^$/d' -e 's/LZ/  /g' -e 's/del/   /g' \
    -e 's/\(\([0-9]\{1,3\}[\.]\)\{3\}[0-9]\{1,3\}\([\/][0-9]\{1,2\}\)\{0,1\}\)/LZ\1LZ/g' \
    -e 's/^.*\(LZ\([0-9]\{1,3\}[\.]\)\{3\}[0-9]\{1,3\}\([\/][0-9]\{1,2\}\)\{0,1\}LZ\).*$/\1/g' \
    -e '/^[^L][^Z]/d' -e '/[^L][^Z]$/d' -e '/^.\{0,10\}$/d' \
    -e '/[3-9][0-9][0-9]/d' -e '/[2][6-9][0-9]/d' -e '/[2][5][6-9]/d' -e '/[\/][4-9][0-9]/d' \
    -e '/[\/][3][3-9]/d' \
    -e "s/^LZ\(.*\)LZ$/-! del ${2} \1/g" \
    -e '/^[^-]/d' \
    -e '/^[-][^!]/d' "${1}" | \
    awk '{print $0} END{print "COMMIT"}' | ipset restore > /dev/null 2>&1
    sed -e 's/\(^[^#]*\)[#].*$/\1/g' -e '/^$/d' -e 's/LZ/  /g' -e 's/add/   /g' \
    -e 's/\(\([0-9]\{1,3\}[\.]\)\{3\}[0-9]\{1,3\}\([\/][0-9]\{1,2\}\)\{0,1\}\)/LZ\1LZ/g' \
    -e 's/^.*\(LZ\([0-9]\{1,3\}[\.]\)\{3\}[0-9]\{1,3\}\([\/][0-9]\{1,2\}\)\{0,1\}LZ\).*$/\1/g' \
    -e '/^[^L][^Z]/d' -e '/[^L][^Z]$/d' -e '/^.\{0,10\}$/d' \
    -e '/[3-9][0-9][0-9]/d' -e '/[2][6-9][0-9]/d' -e '/[2][5][6-9]/d' -e '/[\/][4-9][0-9]/d' \
    -e '/[\/][3][3-9]/d' \
    -e "s/^LZ\(.*\)LZ$/-! add ${2} \1/g" \
    -e '/^[^-]/d' \
    -e '/^[-][^!]/d' "${1}" | \
    awk '{print $0} END{print "COMMIT"}' | ipset restore > /dev/null 2>&1
}

get_ipv4_data_file_item_total() {
    local retval="0"
    [ -f "${1}" ] && {
        retval="$( sed -e 's/\(^[^#]*\)[#].*$/\1/g' -e '/^$/d' -e 's/LZ/  /g' \
        -e 's/\(\([0-9]\{1,3\}[\.]\)\{3\}[0-9]\{1,3\}\([\/][0-9]\{1,2\}\)\{0,1\}\)/LZ\1LZ/g' \
        -e 's/^.*\(LZ\([0-9]\{1,3\}[\.]\)\{3\}[0-9]\{1,3\}\([\/][0-9]\{1,2\}\)\{0,1\}LZ\).*$/\1/g' \
        -e '/^[^L][^Z]/d' -e '/[^L][^Z]$/d' -e '/^.\{0,10\}$/d' \
        -e '/[3-9][0-9][0-9]/d' -e '/[2][6-9][0-9]/d' -e '/[2][5][6-9]/d' -e '/[\/][4-9][0-9]/d' \
        -e '/[\/][3][3-9]/d' "${1}" | grep -c '^[L][Z].*[L][Z]$' )"
    }
    echo "${retval}"
}

get_ipset_total() {
    local retval="$( ipset -q list "${1}" | grep -Ec '^([0-9]{1,3}[\.]){3}[0-9]{1,3}' )"
    echo "${retval}"
}

print_wan_ispip_item_num() {
    echo "$(lzdate) ${MY_LINE}"
    logger -p 1 "${MY_LINE}"
    local index="0" name="" num="0"
    until [ "${index}" -ge "${MAX_WAN_PORT}" ]
    do
        eval name="\${ISPIP_SET_${index}}"
        if [ "$( ipset -q -n list "${name}" )" ]; then
            num="$( get_ipset_total "${name}" )"
            printf "%s %-12s %-13s\t%s\n" "$(lzdate) [$$]:  " "wan${index}" "${name}" "${num}" 
            logger -p 1 "$( printf "%s %-6s\t%-13s%s\n" "[$$]:  " "wan${index}" "${name}" "${num}" )"
        fi
        let index++
    done
}

print_wan_ip() {
    local ifn="$( ip route show default 2> /dev/null | awk '{if ($5 != "") print $5}' )"
    [ -z "${ifn}" ] && return
    echo "$(lzdate) ${MY_LINE}"
    logger -p 1 "${MY_LINE}"
    for ifn in ${ifn}
    do
        ip -4 -o address show dev "${ifn}" 2> /dev/null \
            | awk '{
                ifa=$4
                if (ifa == "") ifa=$2
                psn=index(ifa, "/")
                if (psn > 0) ifa=substr(ifa, 1, psn-1)
                print $2,ifa,system("curl -s --connect-timeout 20 --interface "ifa" -w n ""'"${PIPDN}"'"" 2> /dev/null")
            }' \
            | awk -Fn '{print $1}' \
            | awk '{
                strbuf=sprintf("%s\t%-15s\t%s","'"[$$]:   "'"$1,$2,$3)
                printf("%s %s\n","'"$(lzdate)"'",strbuf)
                system("logger -p 1 "strbuf)
            }'
    done
}

load_ipsets() {
    local index="0" port="0" name="" num="0"
    until [ "${index}" -ge "${ISP_TOTAL}" ]
    do
        eval port="\${ISP_${index}_WAN_PORT}"
        eval add_net_address_sets "${PATH_DATA}/\${ISP_DATA_${index}}" "\${ISPIP_SET_${port}}"
        eval name="\${ISP_NAME_${index}}"
        eval num="\$( get_ipv4_data_file_item_total ${PATH_DATA}/\${ISP_DATA_${index}} )"
        printf "%s %-11s\t%-6s\t\t%s\n" "$(lzdate) [$$]:  " "${name}" "wan${port}" "${num}" 
        logger -p 1 "$( printf "%s %-11s\t%-6s\t%s\n" "[$$]:  " "${name}" "wan${port}" "${num}" )"
        let index++
    done
    print_wan_ispip_item_num
    print_wan_ip
}

create_url_list() {
    rm -f "${PATH_TMP_DATA}/${ISPIP_FILE_URL_LIST}" > /dev/null 2>&1
    local index="0"
    until [ "${index}" -ge "${ISP_TOTAL}" ]
    do
        eval echo "${UPDATE_ISPIP_DATA_DOWNLOAD_URL}/\${ISP_DATA_${index}}" >> "${PATH_TMP_DATA}/${ISPIP_FILE_URL_LIST}" 2> /dev/null
        let index++
    done
}

update_isp_data() {
    # 去苍狼山庄（https://ispip.clang.cn/）下载ISP网络运营商CIDR网段数据文件
    echo "$(lzdate)" [$$]: Start to update the ISP IP data files...
    logger -p 1 "[$$]: Start to update the ISP IP data files..."
    [ ! -d "${PATH_TMP_DATA}" ] && mkdir -p "${PATH_TMP_DATA}" > /dev/null 2>&1
    rm -f "${PATH_TMP_DATA}"/* > /dev/null 2>&1
    create_url_list
    local retval="1"
    local retry_count="1"
    local retry_limit="$(( RETRY_NUM + retry_count ))"
    while [ "${retry_count}" -le "${retry_limit}" ]
    do
        if [ ! -f "${PATH_DATA}/cookies.isp" ]; then
            if wget -q -nc -c --timeout=20 --random-wait --user-agent="Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US)" --prefer-family=IPv4 --referer="${UPDATE_ISPIP_DATA_DOWNLOAD_URL}" --save-cookies="${PATH_DATA}/cookies.isp" --keep-session-cookies --no-check-certificate -P "${PATH_TMP_DATA}" -i "${PATH_TMP_DATA}/${ISPIP_FILE_URL_LIST}";
            then
                retval="0"
                break
            fi
        else
            if  wget -q -nc -c --timeout=20 --random-wait --user-agent="Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US)" --prefer-family=IPv4 --referer="${UPDATE_ISPIP_DATA_DOWNLOAD_URL}" --load-cookies="${PATH_DATA}/cookies.isp" --keep-session-cookies --no-check-certificate -P "${PATH_TMP_DATA}" -i "${PATH_TMP_DATA}/${ISPIP_FILE_URL_LIST}";
            then
                retval="0"
                break
            fi
        fi
        let retry_count++
        sleep "5s"
    done
    if [ "${retval}" = "0" ]; then
        echo "$(lzdate)" [$$]: Download the ISP IP data files successfully.
        logger -p 1 "[$$]: Download the ISP IP data files successfully."
        [ ! -d "${PATH_DATA}" ] && mkdir -p "${PATH_DATA}"
        ! mv -f "${PATH_TMP_DATA}"/*"_cidr.txt" "${PATH_DATA}" > /dev/null 2>&1 && retval="1"
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
        eval [ ! -f "${PATH_DATA}/\${ISP_DATA_${index}}" ] && return 1
        let index++
    done
    return 0
}

load_update_task() {
    echo "$(lzdate) ${MY_LINE}"
    logger -p 1 "${MY_LINE}"
    if [ "${INTERVAL_DAY}" = "0" ]; then
        echo "$(lzdate)" [$$]: The scheduled update task was not started.
        logger -p 1 "[$$]: The scheduled update task was not started."
        if crontab -l | grep -q "^[^#]*${PROJECT_ID}"; then
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
    num="$(  crontab -l | grep -c "^[^#]*${PROJECT_ID}" )"
    if [ "${num}" = "1" ] \
        && ! crontab -l | awk -v xm="${xmode}" '!/^[ ]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {
            if (xm == "0" && $1 == "'"${timer_min}"'" && $2 == "'"${timer_hour}"'" && $3 == "'"${interval_day}"'" && $4 == "*" && $5 == "*") exit 1
            if (xm == "1" && $3 == "'"${interval_day}"'" && $4 == "*" && $5 == "*") exit 1
            if (xm == "2" && $1 == "'"${timer_min}"'" && $3 == "'"${interval_day}"'" && $4 == "*" && $5 == "*") exit 1
            if (xm == "3" && $2 == "'"${timer_hour}"'" && $3 == "'"${interval_day}"'" && $4 == "*" && $5 == "*") exit 1
        }'; then
        timer_min="$( crontab -l | awk '!/^[ ]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {print $1}' | sed 's/^[0-9]$/0&/g' )"
        timer_hour="$( crontab -l | awk '!/^[ ]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {print $2}' )"
        interval_day="$( crontab -l | awk '!/^[ ]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {print $3}' | cut -d '/' -f2 )"
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
    if ! crontab -l | grep -q "^[^#]*${PROJECT_ID}"; then
        echo "${timer_min} ${timer_hour} ${interval_day} * * /bin/sh ${PATH_LZ}/${PROJECT_FILENAME} update > /dev/null 2>&1 # Added by LZ" >> "${CRONTABS_ROOT_FILENAME}" 2> /dev/null
    fi
    timer_min="$( crontab -l | awk '!/^[ ]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {print $1}' | sed 's/^[0-9]$/0&/g' )"
    timer_hour="$( crontab -l | awk '!/^[ ]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {print $2}' )"
    interval_day="$( crontab -l | awk '!/^[ ]*[#]/ && $0 ~ "'"${PROJECT_ID}"'" {print $3}' | cut -d '/' -f2 )"
    [ "${interval_day}" = "1" ] && suffix_str=""
    echo "$(lzdate)" [$$]: "  Update ISP Data: ${timer_hour}:${timer_min} Every ${interval_day} day${suffix_str}"
    echo "$(lzdate) ${MY_LINE}"
    echo "$(lzdate)" [$$]: The scheduled update task was loaded successfully.
    logger -p 1 "[$$]:   Update ISP Data: ${timer_hour}:${timer_min} Every ${interval_day} day${suffix_str}"
    logger -p 1 "${MY_LINE}"
    logger -p 1 "[$$]: The scheduled update task was loaded successfully."
}

unload_update_task() {
    ! crontab -l | grep -q "^[^#]*${PROJECT_ID}" && {
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
            echo "$(lzdate)" [$$]: The bootstrap has been loaded.
            logger -p 1 "[$$]: The bootstrap has been loaded."
            break
        }
        sed -i "/^[^#]*${PROJECT_ID}/d" "${BOOT_START_FILENAME}" > /dev/null 2>&1
        sed -i "1i /bin/sh ${PATH_LZ}/${PROJECT_FILENAME} update # Added by LZ" "${BOOT_START_FILENAME}" > /dev/null 2>&1
        grep -q "^[^#]*${PATH_LZ}/${PROJECT_FILENAME}" "${BOOT_START_FILENAME}" 2> /dev/null && {
            echo "$(lzdate)" [$$]: The bootstrap was loaded successfully.
            logger -p 1 "[$$]: The bootstrap was loaded successfully."
            break
        }
        sed -i "/^[ ]*exit[ ]*[0]/d" "${BOOT_START_FILENAME}" > /dev/null 2>&1
        echo -e "/bin/sh ${PATH_LZ}/${PROJECT_FILENAME} update # Added by LZ\nexit 0" >> "${BOOT_START_FILENAME}" 2> /dev/null
        echo "$(lzdate)" [$$]: The bootstrap was loaded successfully.
        logger -p 1 "[$$]: The bootstrap was loaded successfully."
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
    [ "${PARAM_TOTAL}" = "0" ] && return 0
    if [ "${HAMMER}" = "${UPDATE}" ]; then
        update_isp_data && return 0
        return 1
    elif [ "${HAMMER}" = "${UNLOAD}" ]; then
        unload_update_task
        unload_system_boot
        delete_ipsets
        echo "$(lzdate)" [$$]: All ISP data have been unloaded.
        logger -p 1 "[$$]: All ISP data have been unloaded."
        return 1
    fi
    echo "$(lzdate)" [$$]: Oh, you\'re using the wrong command.
    logger -p 1 "[$$]: Oh, you're using the wrong command."
    return 1
}

print_header_info() {
    echo "$(lzdate)" [$$]:
    echo "$(lzdate)" [$$]: LZ RULES "${LZ_VERSION}" script commands start...
    echo "$(lzdate)" [$$]: By LZ \(larsonzhang@gmail.com\)
    echo "$(lzdate) ${MY_LINE}"
    echo "$(lzdate)" [$$]: Location: "${PATH_LZ}"
    echo "$(lzdate) ${MY_LINE}"

    logger -p 1 "[$$]: "
    logger -p 1 "[$$]: LZ RULES ${LZ_VERSION} script commands start..."
    logger -p 1 "[$$]: By LZ (larsonzhang@gmail.com)"
    logger -p 1 "${MY_LINE}"
    logger -p 1 "[$$]: Location: ${PATH_LZ}"
    logger -p 1 "${MY_LINE}"
}

print_tail_info() {
    echo "$(lzdate) ${MY_LINE}"
    echo "$(lzdate)" [$$]: LZ RULES "${LZ_VERSION}" script commands executed!
    echo "$(lzdate)" [$$]:

    logger -p 1 "${MY_LINE}"
    logger -p 1 "[$$]: LZ RULES ${LZ_VERSION} script commands executed!"
    logger -p 1 "[$$]: "
}


# ---------------------执行代码---------------------

print_header_info

while true
do
    command_parsing || break
    ! check_isp_data && { ! update_isp_data && break; }
    cleaning_user_data
    delete_ipsets
    create_ipsets
    load_ipsets
    load_update_task
    load_system_boot
    break
done

print_tail_info

# END
