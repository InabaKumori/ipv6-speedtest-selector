#!/bin/bash

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
interface_name=$(ip -6 route | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
current_ipv6=$(ip -6 addr show $interface_name | grep 'inet6' | grep -v 'fe80' | awk '{print $2}' | cut -d'/' -f1 | head -n 1)
current_prefix_length=$(ip -6 addr show $interface_name | grep 'inet6' | grep -v 'fe80' | awk '{print $2}' | cut -d'/' -f2 | head -n 1)

# echo "$current_ipv6"

# Normalize and Expand the Current IPv6 Address
current_ipv6_normalized="$current_ipv6"
# Start with the original address
# Replace "::" with the appropriate number of "0000:" 
colon_count=$(echo "$current_ipv6" | grep -o ":" | wc -l)
missing_groups=$(( 8 - $colon_count ))
if (( missing_groups > 0 )); then
    padding=$(printf ':0000%.0s' $(seq 1 $missing_groups))
    current_ipv6_normalized="${current_ipv6/::/$padding:}"
fi

# Pad shortened hexadecimal groups with zeros and replace ":0:" with ":0000:"
current_ipv6_expanded=""
for group in $(echo "$current_ipv6_normalized" | tr ":" "\n"); do
    if [ "${#group}" -lt 4 ]; then
        group="$(printf "%04x" 0x"$group")"
    fi
    current_ipv6_expanded+="$group:"
done
current_ipv6_expanded="${current_ipv6_expanded%:}" # Remove trailing colon

# echo "IPv6 Address without Colons: $current_ipv6_expanded"

current_ipv6_no_slashes=$(echo $current_ipv6_expanded | tr -d ':')  # Use expanded variable here
fixed_part=${current_ipv6_no_slashes:0:$fixed_digits}
#echo "$fixed_part"
#echo "$current_ipv6_no_slashes"


echo ""
echo "Current IPv6 configured on the network interface: $current_ipv6_expanded"
echo "IPv6 assigned to this virtual machine: $current_ipv6/$current_prefix_length"
echo ""
read -p "Please enter the number of IPv6 addresses to test (recommended less than 500 for 512M instances): " ipv6_num
if ! [[ "$ipv6_num" =~ ^[0-9]+$ ]]; then
    echo "Invalid input! Please enter a valid number."
    exit 1
fi
if [ "$ipv6_num" -eq 0 ]; then
    echo "Please check if the entered quantity is correct."
    exit 1
fi
if echo "$ipv6_num 18446744073709551615" | awk '{exit !($1>$2)}'; then
    echo "$ipv6_num addresses? Your instance is going to smoke!"
    exit 1
fi

echo ""
read -p "Please enter the IPv6 prefix length (range: 1-128, default: $current_prefix_length): " prefix_length
if [ -z "$prefix_length" ]; then
    prefix_length=$current_prefix_length
elif ! [[ "$prefix_length" =~ ^[0-9]+$ ]]; then
    echo "Prefix length must be a number!"
    exit 1
elif [ "$prefix_length" -lt 1 ] || [ "$prefix_length" -gt 128 ]; then
    echo "Prefix length must be between 1 and 128!"
    exit 1
fi

echo ""
echo "Generating $ipv6_num IPv6 addresses with prefix length $prefix_length for testing. Please wait for the task to complete."

declare -a ipv6_array=()
declare -A used_ip_addrs
used_ip_addrs[$current_ipv6]=1
current_count=0

# Create/Clear ipv6.txt
> ipv6.txt

# Calculate fixed and random part lengths
fixed_digits=$((prefix_length/4))
random_digits=$((32-fixed_digits))

for (( i=0; i<$ipv6_num; i++ )); do
    while : ; do
        # Use the initial part of the current IPv6 address up to the specified prefix length

        # Normalize and Expand the Current IPv6 Address
        current_ipv6_normalized="$current_ipv6"
        # Start with the original address
        # Replace "::" with the appropriate number of "0000:"
        colon_count=$(echo "$current_ipv6" | grep -o ":" | wc -l)
        missing_groups=$(( 8 - $colon_count ))
        if (( missing_groups > 0 )); then
            padding=$(printf ':0000%.0s' $(seq 1 $missing_groups))
            current_ipv6_normalized="${current_ipv6/::/$padding:}"
        fi

        # Pad shortened hexadecimal groups with zeros and replace ":0:" with ":0000:"
        current_ipv6_expanded=""
        for group in $(echo "$current_ipv6_normalized" | tr ":" "\n"); do
            if [ "${#group}" -lt 4 ]; then
                group="$(printf "%04x" 0x"$group")"
            fi
            current_ipv6_expanded+="$group:"
        done
        current_ipv6_expanded="${current_ipv6_expanded%:}" # Remove trailing colon

        # echo "IPv6 Address without Colons: $current_ipv6_expanded"

        current_ipv6_no_slashes=$(echo $current_ipv6_expanded | tr -d ':')  # Use expanded variable here
        fixed_part=${current_ipv6_no_slashes:0:$fixed_digits}

        random_part=""
        for (( j=0; j<$random_digits; j++ )); do
            random_part+=$(printf '%x' $((RANDOM%16)))
        done

        full_address=$(printf "%s%s" "$fixed_part" "$random_part")
        test_ipv6=$(echo "$full_address" | sed 's/.\{4\}/&:/g;s/:$//')

        # Ensure the address has 8 groups
        while [ $(echo $test_ipv6 | tr -cd ':' | wc -c) -lt 7 ]; do
            test_ipv6+=":0000"
        done

        if [ -z ${used_ip_addrs[$test_ipv6]} ]; then
            sudo ip addr add "$test_ipv6"/$prefix_length dev $interface_name 2>/dev/null
            used_ip_addrs[$test_ipv6]=1
            ipv6_array+=($test_ipv6)
            ((current_count++))
            print_progress_bar $current_count $ipv6_num

            # Append to ipv6.txt
            echo "        inet6 $test_ipv6  prefixlen $prefix_length  scopeid 0x0<global>" >> ipv6.txt
            break
        else
            echo "IPv6 address $test_ipv6 already exists, regenerating..."
        fi
    done
done

sleep 1s
echo -e "\n====================================================="
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
echo "Total script execution time: $elapsed_time seconds."
echo "IPv6 addresses have been saved to ipv6.txt"
