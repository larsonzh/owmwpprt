#!/bin/sh
# lzrules.sh v1.0.0
# By LZ 妙妙呜 (larsonzhang@gmail.com)

# LZ RULES script for OpenWrt based router

# 脚本命令 (假设当前在lz目录)
# 加载数据规则         ./lzrules.sh
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

# 定时更新ISP网络运营商CIDR网段数据失败后自动重试次数
# 0--不重试；>0--重试次数；取值范围：0~99
# 缺省为重试5次。
RETRY_NUM=5
# 若自动重试后经常下载失败，建议自行前往https://ispip.clang.cn/网站手工下载获取与上述10个网络运营商网段数据
# 文件同名的最新CIDR网段数据，下载后直接粘贴覆盖/etc/lz/data/目录内同名数据文件，重启脚本即刻生效。


# ---------------------全局变量---------------------

# 版本号
LZ_VERSION=v1.0.0

# 项目文件路径
PATH_LZ="${0%/*}"
[ "${PATH_LZ:0:1}" != '/' ] && PATH_LZ="$( pwd )${PATH_LZ#*.}"
PATH_DATA="${PATH_LZ}/data"
PATH_TMP="${PATH_LZ}/tmp"

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

# 更新ISP网络运营商CIDR网段数据文件临时下载目录
PATH_TMP_DATA="${PATH_TMP}/download"

# ISP网络运营商CIDR网段数据文件下载站点URL
UPDATE_ISPIP_DATA_DOWNLOAD_URL="https://ispip.clang.cn"

# ISP网络运营商CIDR网段数据文件URL列表文件名
ISPIP_FILE_URL_LIST="ispip_file_url_list.lst"

# 脚本命令
HAMMER="$( echo "${1}" | tr '[:A-Z:]' '[:a-z:]' )"
UPDATE="update"
UNLOAD="unload"
PARAM_TOTAL="${#}"


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
    ! echo "${RETRY_NUM}" | grep -qE '^[0-9]$|^[1-9][0-9]' && RETRY_NUM="5"
}

delete_ipsets() {
    local port="0"
    until [ "${port}" -ge "${MAX_WAN_PORT}" ]
    do
        eval ipset -q flush "\${ISPIP_SET_${port}}" && eval ipset -q destroy "\${ISPIP_SET_${port}}"
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

load_ipsets() {
    local isp_name_0="CTCC          "
    local isp_name_1="CUCC/CNC      "
    local isp_name_2="CMCC          "
    local isp_name_3="CRTC          "
    local isp_name_4="CERNET        "
    local isp_name_5="GWBN          "
    local isp_name_6="Other         "
    local isp_name_7="Hongkong      "
    local isp_name_8="Macao         "
    local isp_name_9="Taiwan        "
    local index="0" port="0" name="" num="0"
    until [ "${index}" -ge "${ISP_TOTAL}" ]
    do
        eval port="\${ISP_${index}_WAN_PORT}"
        eval add_net_address_sets "${PATH_DATA}/\${ISP_DATA_${index}}" "\${ISPIP_SET_${port}}"
        eval name="\${isp_name_${index}}"
        eval num="\$( get_ipv4_data_file_item_total ${PATH_DATA}/\${ISP_DATA_${index}} )"
        echo "$(lzdate)" [$$]: "   ${name} wan${port}          ${num}"
        logger -p 1 "[$$]:    ${name} wan${port}          ${num}"
        let index++
    done
    echo "$(lzdate)" [$$]: ------------------------------------------
    logger -p 1 "[$$]: ------------------------------------------"
    index="0"
    until [ "${index}" -ge "${MAX_WAN_PORT}" ]
    do
        eval name="\${ISPIP_SET_${index}}"
        if [ "$( ipset -q -n list "${name}" )" ]; then
            num="$( get_ipset_total "${name}" )"
            echo "$(lzdate)" [$$]: "   wan${index}       ${name}       ${num}"
            logger -p 1 "[$$]:    wan${index}       ${name}       ${num}"
        fi
        let index++
    done
    echo "$(lzdate)" [$$]: ------------------------------------------
    echo "$(lzdate)" [$$]: All ISP data of the policy route have been loaded.
    logger -p 1 "[$$]: ------------------------------------------"
    logger -p 1 "[$$]: All ISP data of the policy route have been loaded."
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
        echo "$(lzdate)" [$$]: ------------------------------------------
        logger -p 1 "[$$]: Update the ISP IP data files successfully."
        logger -p 1 "[$$]: ------------------------------------------"
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

command_parsing() {
    [ "${PARAM_TOTAL}" = "0" ] && return 0
    if [ "${HAMMER}" = "${UPDATE}" ]; then
        update_isp_data && return 0
        return 1
    elif [ "${HAMMER}" = "${UNLOAD}" ]; then
        delete_ipsets
        echo "$(lzdate)" [$$]: All ISP data of the policy route have been unloaded.
        logger -p 1 "[$$]: All ISP data of the policy route have been unloaded."
        return 1
    fi
    echo "$(lzdate)" [$$]: Oh, you\'re using the wrong command.
    logger -p 1 "[$$]: Oh, you're using the wrong command."
    return 1
}


# ---------------------执行代码---------------------

echo "$(lzdate)" [$$]:
echo "$(lzdate)" [$$]: LZ RULES "${LZ_VERSION}" script commands start...
echo "$(lzdate)" [$$]: By LZ \(larsonzhang@gmail.com\)
echo "$(lzdate)" [$$]: ------------------------------------------
echo "$(lzdate)" [$$]: Location: "${PATH_LZ}"
echo "$(lzdate)" [$$]: ------------------------------------------

logger -p 1 "[$$]: "
logger -p 1 "[$$]: LZ RULES ${LZ_VERSION} script commands start..."
logger -p 1 "[$$]: By LZ (larsonzhang@gmail.com)"
logger -p 1 "[$$]: ------------------------------------------"
logger -p 1 "[$$]: Location: ${PATH_LZ}"
logger -p 1 "[$$]: ------------------------------------------"

while true
do
    command_parsing || break
    ! check_isp_data && { ! update_isp_data && break; }
    cleaning_user_data
    delete_ipsets
    load_ipsets
    break
done

echo "$(lzdate)" [$$]: ------------------------------------------
echo "$(lzdate)" [$$]: LZ RULES "${LZ_VERSION}" script commands executed!
echo "$(lzdate)" [$$]:

logger -p 1 "[$$]: ------------------------------------------"
logger -p 1 "[$$]: LZ RULES ${LZ_VERSION} script commands executed!"
logger -p 1 "[$$]: "

# END
