# owmwpprt
OpenWrt Multi WAN Port Policy Routing Tool

OpenWrt 固件多 WAN 口策略路由分流工具

**v2.2.0**

本工具使用 Shell 脚本编写，可在 OpenWrt 固件的路由器上，基于 mwan3 的强大功能，按照各网络运营商互联网地址分布情况，针对路由器上每个 WAN 口生成多个不同的目标网段数据集合，灵活绑定到 mwan3 的 WAN 口策略规则中，实现全网段的多 WAN 口数据流量分流控制策略。

脚本使用的所有 ISP 网络运营商 CIDR 网段数据源自 clang 苍狼山庄 https://ispip.clang.cn/ 整理的APNIC官方每日更新。

脚本作为 mwan3 的配套软件，使用前请到 OpenWrt 中的「Software」界面内搜索并下载安装如下软件：

   - mwan3
   - luci-app-mwan3
   - luci-i18n-mwan3-zh-cn
   - iptables-nft
   - ip6tables-nft
   - wget-ssl
   - curl
   - dnsmasq-full（注：安装前需卸载删除原有的dnsmasq软件包）

**重要说明**

OpenWrt 23.05 固件中对 dnsmasq-full 编译选项做出重大更改，彻底删除 ipset 支持，对 mwan3 及其 ipset 功能产生重大影响。mwan3 目前不支持 nfset，且不能放弃兼容包/翻译包软件后直接支持原生 nftables。现在 ipset 已不能在 23.05 固件上运行，且没有任何可供使用的兼容包/翻译包。

在 mwan3 能够直接支持原生 nftables 或 nfset 之前，建议在 22.03 及以前版本固件下使用本分流工具。OpenWrt 22.03 系列固件主要关注从基于 iptables 的 firewall3 迁移到基于 nftables 的 firewall4，该系列最后一个版本是 22.03.7。

22.03 固件时，请务必安装 iptables-nft 和 ip6tables-nft 两个软件，否则 mwan3 不能正常运行。

一旦 mwan3 正式支持 nfset，作者会对本分流工具软件中用到的 ipset 功能进行 nfset 技术升级。

## **开发环境**

   - 固件版本    OpenWrt 22.03.2 r19803-9a599fee93 / LuCI openwrt-22.03 branch git-22.288.45147-96ec0cd
   - 内核版本    5.10.146
   - 虚拟机  VirtualBox 版本 6.1.36 r152435 (Qt5.6.2)

## **主要功能**

   - 最多可支持 8 个 WAN 口的IPv4/6流量控制。
   - 可按如下 10 个覆盖全国的网络运营商IPv4/6目标网段的划分配置流量出口：
     - 中国电信网段
     - 中国联通/网通网段
     - 中国移动网段
     - 中国铁通网段
     - 中国教育网网段
     - 长城宽带/鹏博士网段
     - 中国大陆其他运营商网段
     - 香港地区运营商网段
     - 澳门地区运营商网段
     - 台湾地区运营商网段
   - 可通过 mwan3 为国外网段数据流量指定路由器出口。
   - 可通过 mwan3 为 IPv4/6 数据流量指定路由器出口。
   - 可任意指定某个目标网段数据流量的路由器出口。
   - 可设置某个目标网段数据流量通过负载均衡自动分配流量出口。
   - 可禁止某个网络运营商目标网段数据的使用。
   - 可自定义任意数量的 IPv4/6 目标网址/网段数据集合，以在 mwan3 的流量出口策略规则中使用。
   - 可自定义任意数量的域名 IPv4 数据集合，按所访问的域名分配流量出口。
   - 可自动/手动下载更新所有网络运营商的 CIDR 网段数据。
   - 可设置定时自动更新的时间及间隔。
   - 可自动在系统计划任务中添加定时更新数据任务，无需人工手动添加。
   - 可自动将脚本添加到系统启动项中，随路由器自动启动，无需人工手动添加。
   - 脚本启动时可自动获取 mwan3 中设定的可用WAN口，并在终端中显示所设置的运营商网段对应的出口信息。
   - 脚本启动时可自动侦测 WAN 口的内网 IP、公网 IP，并在终端中显示。
   - 所有终端上显示输出的信息均同时写入系统日志，可随时在系统日志中查看。
   - 提供脚本卸载数据命令，可将加载到系统启动项、计划任务，以及内存中的所有数据一次性卸载并清理干净。

## **使用指南**

一、设置路由器 WAN 口

   在路由器「网络 - 接口」界面中按照设备实际情况配置两个及以上的 WAN 口。WAN 口设置页面中的「高级设置」选项卡内，在「使用网关跃点」处，指定网关跃点，如 10。第二个 WAN 口设置为 11，以此类推，要求每一个 WAN 口的网关跃点数值唯一，不要有重复。网关跃点数值越小，优先级越高。

![屏幕截图 2022-10-22 042220](https://user-images.githubusercontent.com/73221087/197283255-13f3170e-4ccc-46db-8fca-57f3005730f1.png)

![屏幕截图 2022-10-18 220133](https://user-images.githubusercontent.com/73221087/197303512-411599ce-dfc8-47db-bb34-14373d1bc3ef.png)

二、路由器连接互联网，按前文所述下载安装 5 个必须的支撑软件。

   SSH 终端下载安装命令
```markdown
        opkg update
        opkg install mwan3 luci-app-mwan3 luci-i18n-mwan3-zh-cn
        opkg install iptables-nft ip6tables-nft
        opkg install wget-ssl
        opkg install curl
        opkg remove dnsmasq && opkg install dnsmasq-full
```
三、mwan3 设置

1. 接口

   在路由器「网络 - MultiWAN 管理器」中选择「接口」选项卡，删除其中初始设置的所有接口，使用新增，按照页面中的说明依次添入之前在「网络 - 接口」界面中设置的 WAN 口，名称要保持一致，其中只需勾选「已启用」和将「互联网协议」与之前的接口设置保持一致，其他保持缺省即可。此页面最下面可看到之前在「一、设置路由器 WAN 口」时设置的网关跃点数值，如没有，需到前面设置。

![屏幕截图 2022-10-22 043531](https://user-images.githubusercontent.com/73221087/197285311-5f24ad7e-6104-4b9b-baa8-c3f4ad64fc2e.png)
![屏幕截图 2022-10-22 043445](https://user-images.githubusercontent.com/73221087/197285068-05c8f18d-8b22-4fe1-9439-b9bb10b0b799.png)

![屏幕截图 2022-10-22 044607](https://user-images.githubusercontent.com/73221087/197285936-4892a7ca-c53c-4df2-bd19-7a39feaa0a5b.png)

2. 成员

   在路由器「网络 - MultiWAN 管理器」中选择「成员」选项卡，对应每个 WAN 口添加成员，每个成员的跃点数和权重设置为 1。

![屏幕截图 2022-10-22 044959](https://user-images.githubusercontent.com/73221087/197286729-7ee1e0ec-84be-45b5-8271-4e7012254392.png)

![屏幕截图 2022-10-22 045055](https://user-images.githubusercontent.com/73221087/197286952-dd2ca198-cf8c-42de-99b9-a2a35a167dd7.png)

3. 策略

   在路由器「网络 - MultiWAN 管理器」中选择「策略」选项卡，按照其中的说明，策略是将一个或多个成员分组，控制 mwan3 如何分配流量。此处先给前面设置的每个成员都单独设置一条单一成员的规则，然后设置一条包括所有成员的负载均衡规则备用，以后可根据情况启用。

![屏幕截图 2022-10-22 045616](https://user-images.githubusercontent.com/73221087/197287781-06f66145-dda2-45cd-bff5-d3d722ae6526.png)

![屏幕截图 2022-10-22 050431](https://user-images.githubusercontent.com/73221087/197288631-d14eef7a-4d78-48f4-8468-354caf083d4c.png)

![屏幕截图 2022-10-22 045709](https://user-images.githubusercontent.com/73221087/197287826-be2e5b9d-271b-4485-a4a9-4135da113971.png)

4. 规则

   在路由器「网络 - MultiWAN 管理器」中选择「规则」选项卡，说明中提到规则指定哪些流量将使用特定的 mwan3 策略。

   如果之前有为 IPv6 协议设置的 WAN 口（确定该口是接入 IPv6 流量的 WAN 口），则针对性的的设置一条 IPv6 流量的规则，「互联网协议」选择「仅IPv6」，「协议」选择「all」，「分配的策略」选择用于 IPv6 接口的那一条规则，其余项空置，意味之后所有 IPv6 流量只通过该 WAN 口。

![屏幕截图 2022-10-22 050744](https://user-images.githubusercontent.com/73221087/197289293-7a7f6d65-ea50-43e4-b60c-e1c47e9ba6f8.png)

   针对前面的 IPv4 流量策略，设置两个或以上的 WAN 口规则，每条规则都对应之前的 IPv4 WAN 口策略，这几条规则将用于中国国内流量按运营商网段进行分流。「互联网协议」选择「仅IPv4」，「协议」选择「all」，「分配的策略」选择对应 IPv4 接口的那一条规则，其余项空置，但其中的「IP 配置」暂时不选，留待脚本安装配置完后再填写。

![屏幕截图 2022-10-22 051241](https://user-images.githubusercontent.com/73221087/197290047-5b661ab0-3c84-4bca-b564-b9df304835d7.png)

   单独设置一条用于国外 IPv4 流量的规则，该规则放在所有规则的最下面，当上面所有国内 IPv4 流量规则执行完后，剩下所有未匹配 IPv4 流量规则的流量即为去往国外的流量，此时可以根据需要选择一个上面已经使用过的 WAN 口走国外流量。「互联网协议」选择「仅IPv4」，「协议」选择「all」，「分配的策略」选择对应 IPv4 接口的某条 WAN 口规则，其余项空置。

![屏幕截图 2022-10-22 051841](https://user-images.githubusercontent.com/73221087/197290687-12e1dca8-f328-49ed-b801-011a08cd239c.png)

   负载均衡规则可根据需要添加。「互联网协议」选择「仅IPv4」，「协议」选择「all」，「分配的策略」选择之前包含全部 WAN 口成员的负载均衡规则，其余项空置，但其中的「IP 配置」暂时不选。为避免该规则影响其他出口定向规则的分流，只能将其放在所有规则的最下面，也就是优先级最低。由于上一条国外流量规则会将之前所有未分流的 IPv4 流量悉数带走，所以这条负载均衡规则此处不起什么作用，除非前面的出口出现问题，此时倒是可以作为一种保障手段存在。

![屏幕截图 2025-1-26 054553](https://github.com/user-attachments/assets/1f02f8e5-8412-4595-81ab-5217f83beeac)

   需要记住的是，在规则页面，所有规则都可以上下移动，可很方便的改变相互间对网络流量的过滤匹配顺序，上面的执行优先级高于下面的条目。

![屏幕截图 2022-10-22 055023](https://user-images.githubusercontent.com/73221087/197294100-b39d1b53-29da-4e71-bd7a-ea6028efe85a.png)

四、软件安装

1. 下载本工具的软件压缩包 lzrules-[version ID].tgz（例如：lzrules-v1.1.1.tgz）。

2. 使用 WinSCP 等工具将压缩包上传至路由器的任意目录。

3. 在 SSH 终端中使用解压缩命令在当前目录中将软件解压缩，生成 lzrules-[version ID] 目录（例如：lzrules-v1.1.1），进入其中可看到一个 lzrules 目录，此为脚本的工作目录。
```markdown
        tar -xzvf lzrules-[version ID].tgz
```
4. 将 lzrules 目录复制或剪切粘贴到路由器中希望放置本脚本的位置，则完成本软件的安装。

5. 在 lzrules 目录中，lzrules.sh 为本工具的可执行脚本，若发现无运行权限，请赋予相关属性。data 目录中保存的是 10 个网络运营商 IPv4/6 目标网段的数据文件，不要手工修改或删除。
```markdown
        /lzrules/lzrules.sh -- 主运行脚本
        /lzrules/data/  10 个 ISP 运营商的 IPv4/6 网段数据文件及用户自定义的数据集合列表文件
                        chinatelecom_cidr.txt      -- 中国电信
                        unicom_cnc_cidr.txt        -- 中国联通/网通
                        cmcc_cidr.txt              -- 中国移动
                        crtc_cidr.txt              -- 中国铁通
                        cernet_cidr.txt            -- 中国教育网
                        gwbn_cidr.txt              -- 长城宽带/鹏博士
                        othernet_cidr.txt          -- 中国大陆其他运营商
                        hk_cidr.txt                -- 香港地区运营商
                        mo_cidr.txt                -- 澳门地区运营商
                        tw_cidr.txt                -- 台湾地区运营商
                        chinatelecom_ipv6.txt      -- 中国电信 IPv6
                        unicom_cnc_ipv6.txt        -- 中国联通/网通 IPv6
                        cmcc_ipv6.txt              -- 中国移动 IPv6
                        crtc_ipv6.txt              -- 中国铁通 IPv6
                        cernet_ipv6.txt            -- 中国教育网 IPv6
                        gwbn_ipv6.txt              -- 长城宽带/鹏博士 IPv6
                        othernet_ipv6.txt          -- 中国大陆其他运营商 IPv6
                        hk_ipv6.txt                -- 香港地区运营商 IPv6
                        mo_ipv6.txt                -- 澳门地区运营商 IPv6
                        tw_ipv6.txt                -- 台湾地区运营商 IPv6
                        custom_ipsets_lst.txt      -- 用户自定义 IPv4 目标访问网址/网段数据集合列表文件
                        custom_ipv6_ipsets_lst.txt -- 用户自定义 IPv6 目标访问网址/网段数据集合列表文件
                        dname_ipsets_lst.txt       -- 用户自定义目标访问域名数据集合列表文件
```
五、软件设置

1. 进入 lzrules 目录，使用文本工具打开 lzrules.sh 脚本文件，即可对脚本的工作参数进行配置，退出前注意保存。

   例如，可使用 WinSCP，接入路由器后，在 lzrules 目录中双击 lzrules.sh 文件，即可进入文本编辑模式。当然，也可以使用 vi 命令在 SSH 终端界面里编辑脚本参数。

2. 打开脚本后先看一下前面的文字说明，然后在下面的「用户运行策略自定义区」内，即可根据说明，通过修改缺省参数的方式，对运营商目标网段流量进行出口设置。还可在此区域内设置和修改「定时更新 ISP 网络运营商 CIDR 网段数据时间参数定义」。

   路由器上的 WAN 口是本地网络连接外部广域网络的通信接口。脚本中的 WAN 口不是用户定义和命名的逻辑接口，而是路由器设备上实际的物理网卡接口，或是在网卡设备上定义的 VLAN 子接口。用户在 network 文件或 OpenWrt「网络 - 接口」页面中配置网络接口时，DHCP 客户端、DHCPv6 客户端、PPP、PPPoE、静态地址等相同或不同协议的多个逻辑接口，可以共享使用同一个 WAN 口。在 network 文件或 OpenWrt「网络 - 接口」页面中，排除掉所有本地网络及回环设备后，按照每个物理网卡接口（或 VLAN 子接口）设备，从上到下首次被某个逻辑接口使用或关联时所构成的先后顺序，所有 WAN 口升序排列为「第一 WAN 口」至「第八 WAN 口」，出口参数对应为 0 ~ 7。参数 8 指定访问该网段的流量以负载均衡分配出口。9 为将该网段流量归为未知流量，脚本此时不会处理该网段地址数据，需要由用户直接在 mwan3 中对全部未知流量设置专门的出口策略规则。

   示例中的 WAN 口序列中不包括 IPv6 协议的接口，IPv6 协议的流量出口在「MultiWAN 管理器」中单独配置出口策略规则。

   脚本已涵盖中国地区所有运营商 IPv4/6 目标网段，在分配完所有国内流量后，剩下的就是国外流量，该部分流量出口直接在「MultiWAN 管理器」中按照优先级顺序配置出口策略规则。

![屏幕截图 2022-10-22 055813](https://user-images.githubusercontent.com/73221087/197294991-c557f396-7667-442c-b34b-9d21c3a2fe10.png)

![屏幕截图 2022-10-22 060342](https://user-images.githubusercontent.com/73221087/197295440-e97ebb8b-6233-4c26-afd8-ba5f78aeadbd.png)

   该区域之后为脚本「全局变量」区域，无需用户变更其中的数据，高手除外，可以去随便修改程序，一般用户不建议这么做。当然，能够耍弄 OpenWrt 路由器固件的用户，都不会把自己当成一般用户，呵呵~~~

3. 完成出口设定后，需在路由器「网络 - MultiWAN 管理器 - 规则」界面内，将 WAN 口的网段数据集合名称（如：ISPIP_SET_0）填入「MultiWAN 管理器」内相应 WAN 口策略规则条目中的「IP 配置」字段内（如对应第一 WAN 口的策略规则），形成绑定关系，最终通过 OpenWrt 内的 mwan3 软件完成多 WAN 口流量的策略路由。填写时，在下拉框中选择「自定义」，在输入框中书写完毕后按回车键，即可完成数据集合名称的输入。卸载脚本时，请在下拉框中选择「--请选择--」项，然后按页面中的「保存」，最后在「规则」界面中「保存并应用」，就可以解除该WAN口数据集合与相应规则的绑定关系。

![屏幕截图 2022-10-22 061252](https://user-images.githubusercontent.com/73221087/197296304-4ca19e25-1c0e-4d3f-a67e-3dbf3d89e222.png)

   脚本的主要作用就是为 mwan3 生成可供其多个 WAN 口通道选择使用的目标流量网段数据集合，从而实现更为复杂的业务策略。

   WAN 口的网段数据集合名称在「用户运行策略自定义区」结束前，以多个「WAN 口国内网段数据集合名称」变量赋值等式的方式呈现，等号右边引号内即为相应 WAN 口的数据集合名称，此名称可以修改，但修改前一定要执行一次脚本的「卸载运行数据」命令，确保之前的数据在设备中被彻底清除，然后要及时修改 mwan3 策略条目中已绑定的数据集合名称。

![屏幕截图 2022-10-22 060726](https://user-images.githubusercontent.com/73221087/197295967-0a3fb79e-8636-4734-a2ba-4a2f03a67195.png)

   「WAN 口国内网段数据集合名称」中最后一个「ISPIP_SET_B」变量专用于运营是网段的多 WAN 口负载均衡，使用时填入多 WAN 口负载均衡规则条目的「IP 配置」字段内。

![屏幕截图 2025-1-26 061804](https://github.com/user-attachments/assets/4a7cb8b5-4e61-41fe-9ce9-d9fd59a507bf)

4. 如需在 mwan3 的 WAN 口流量策略规则设置中使用自定义 IPv4 目标访问网址/网段数据集合，可在脚本的「用户运行策略自定义区」里启用「用户自定义 IPv4 目标访问网址/网段数据集合列表文件（custom_ipsets_lst.txt）」功能，使用方法参照其中的使用说明。

5. 如需在 mwan3 的 WAN 口流量策略规则设置中使用自定义 IPv6 目标访问网址/网段数据集合，可在脚本的「用户运行策略自定义区」里启用「用户自定义 IPv6 目标访问网址/网段数据集合列表文件（custom_ipv6_ipsets_lst.txt）」功能，使用方法参照其中的使用说明。

6. 如需在 mwan3 的 WAN 口流量策略规则设置中实现按所访问的域名分配流量出口的策略，可在脚本的「用户运行策略自定义区」里启用「用户自定义目标访问域名数据集合列表文件（dname_ipsets_lst.txt）」功能，使用方法参照其中的使用说明。

7. 上述设置完成后，即可在脚本所在目录内执行脚本启动命令，为 mwan3 加载规则数据：
```markdown
    脚本启动命令 (假设当前在 lzrules 目录)
        ./lzrules.sh
```
   提示：修改脚本工作参数、系统网络端口配置、mwan3 配置参数后，需重新启动脚本。

   脚本启动过程中将会在 SSH 终端显示网段流量出口配置信息，各运营是网段数据条目数、各出口用于网段数据匹配过滤的条目数，各出口的网口 IP 地址，公网出口 IP 地址等信息，同时将信息传入系统日志中，会自动在系统计划任务中添加定时更新任务，并将脚本添加进系统启动项中。

![屏幕截图 2022-10-22 063041](https://user-images.githubusercontent.com/73221087/197298966-6ec58f18-dab9-40f2-ac08-5de28bd7a79a.png)

![屏幕截图 2022-10-22 073034](https://user-images.githubusercontent.com/73221087/197305169-3528a830-61a0-4a19-9ee2-590abd25b5db.png)

![屏幕截图 2022-10-22 073123](https://user-images.githubusercontent.com/73221087/197305183-2f305ccb-bcf5-4b28-a514-77793d3446cd.png)

![屏幕截图 2022-10-22 073916](https://user-images.githubusercontent.com/73221087/197305866-495ecd4a-d047-4b92-bbe5-c185b7d7de9d.png)

![屏幕截图 2022-10-18 210656](https://user-images.githubusercontent.com/73221087/197304519-23931bf8-3ba6-46ff-9159-47d8b10c2f91.png)

六、脚本运行命令
```markdown
    脚本命令 (假设当前在 lzrules 目录)
        加载规则数据         ./lzrules.sh
        更新数据文件         ./lzrules.sh update
        卸载运行数据         ./lzrules.sh unload
```

七、软件卸载

1. 首先执行脚本的「卸载运行数据」命令：
```markdown
    脚本命令 (假设当前在 lzrules 目录)
        卸载运行数据         ./lzrules.sh unload
```
   此命令执行后可将加载到系统启动项、计划任务，以及内存中的所有数据一次性卸载和清理干净。

![屏幕截图 2022-10-22 065240](https://user-images.githubusercontent.com/73221087/197301882-2a23df12-4670-42ad-bc98-23902e4baa56.png)

2. 在路由器「网络 - MultiWAN 管理器 - 规则」界面内，按「编辑」进入绑定过脚本网段数据集合的规则条目页面，「IP 配置」字段下拉框中内将脚本数据集合名称改为「--请选择--」项，然后点击「保存」，即可解除绑定。依次类推，解除所有绑定关系。

3. 在路由器「网络 - DHCP/DNS - IP集」选项卡界面内，逐条删除所有在脚本定义过的域名数据集合条目。

![屏幕截图 2022-10-22 065725](https://user-images.githubusercontent.com/73221087/197302924-cff2fd14-1fda-4e87-aa37-4a3cf3020613.png)

4. 删除 lzrules 目录，脚本软件至此全部清除，OpenWrt 固件设置恢复原状。

## 捐助

小众需求，开源不易，欢迎投喂 😘

| ![Wechat Pay](/images/wechat.png) | ![Alipay](/images/alipay.png) |
|--------------------------------------------------|--------------------------------------------------|
