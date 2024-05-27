#!/bin/bash

ping_ipv6() {
    local src_ip=$1
    local target_ipv6=$2
    local temp_file=$3
    local ping_output=$(ping6 -I $src_ip -i 0.3 -c 30 $target_ipv6 2>&1)
    # ip addr del $src_ip/64 dev $interface_name  <-- Remove this line to keep addresses
    local loss=$(echo "$ping_output" | grep 'packets transmitted' | awk '{print $6}')
    if [ "$loss" == "100%" ]; then
        return
    fi
    local min=$(echo "$ping_output" | grep 'rtt min/avg/max/mdev' | cut -d'=' -f2 | awk -F'/' '{print $2}')
    echo "$src_ip $min" >> "$temp_file"
}

print_progress_bar() {
    local -i current=$1
    local -i total=$2
    local filled=$((current*60/total))
    local bars=$(printf "%-${filled}s" "|" | tr ' ' '|')
    local spaces=$(printf "%-$((60-filled))s" " ")
    local percent=$((current*100/total))
    echo -ne "[${bars}${spaces}] ${percent}% ($current/$total)\r"
}

start_time=$(date +%s)
interface_name=$(ip -6  route | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
current_ipv6=$(ip -6 addr show $interface_name | grep 'inet6' | grep -v 'fe80' | awk '{print $2}' | cut -d'/' -f1 | head -n 1)
current_prefix=$(echo $current_ipv6 | cut -d':' -f1-4)
echo ""
echo "网卡当前配置的IPv6： $current_ipv6"
echo "分配该虚拟机的IPv6： $current_prefix::/64"
echo ""
stty erase '^H' && read -p "请输入你要测试多少个IPv6（建议512M机型小于500个）: " ipv6_num
if ! [[ "$ipv6_num" =~ ^[0-9]+$ ]]; then
    echo "写的啥玩意？认真点！"
    exit 1
fi
if [ "$ipv6_num" == 0 ]; then
    echo "你看看你输的数量对吗？"
    exit 1
fi
if echo "$ipv6_num 18446744073709551615" | awk '{exit !($1>$2)}'; then
    echo "$ipv6_num个？你的小鸡要冒烟咯！"
    exit 1
fi

echo ""
echo "在 $current_prefix::/64 中生成$ipv6_num个IPv6进行检测 请等待任务完成"

declare -a ipv6_array=()
declare -A used_ip_addrs 
used_ip_addrs[$current_ipv6]=1
current_count=0

# Create/Clear ipv6.txt
> ipv6.txt

for (( i=0; i<$ipv6_num; i++ )); do
    while : ; do
        random_part=$(printf '%x:%x:%x:%x' $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)))
        test_ipv6="$current_prefix:$random_part"
        if [ -z ${used_ip_addrs[$test_ipv6]} ]; then
            sudo ip addr add "$test_ipv6"/64 dev $interface_name 2>/dev/null
            used_ip_addrs[$test_ipv6]=1
            ipv6_array+=($test_ipv6)
            ((current_count++))
            print_progress_bar $current_count $ipv6_num

            # Append to ipv6.txt
            echo "        inet6 $test_ipv6  prefixlen 64  scopeid 0x0<global>" >> ipv6.txt
            break
         else
           echo "IPv6地址 $test_ipv6 已存在，正在重新生成..."
        fi
    done
done


sleep 5s 
echo "====================================================="
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
echo "脚本总耗时: $elapsed_time 秒。"
echo "Power by PoloCloud@Wang_Boluo Mod by @KorenKrita" #给个面子别删吧哥

echo "IPv6 addresses have been saved to ipv6.txt"
