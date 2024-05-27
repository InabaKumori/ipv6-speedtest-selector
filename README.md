# IPv6 Speed Test and Selection Script

## Overview

This repository contains two scripts to help you identify and use the fastest IPv6 addresses from your assigned subnet. The scripts have been tested successfully on Linux and are designed to be easy to use, even if you're new to Linux or scripting.

**Why use this?**  Using a faster IPv6 address can potentially improve your network speeds and reduce latency, especially if your ISP has good IPv6 support.

## Requirements

* **A Linux server:** The main script (ipv6_gen.sh) needs to be run on the server where you want to test and select the IPv6 addresses.
* **Python 3:** The second script (ipv6.py) requires Python 3 to be installed on your local machine (where you want to analyze the ping results).

## Instructions

### Step 1: Generate and Test IPv6 Addresses (On Your Server)

1. **Connect to your server** via SSH.

2. **Clone the repository:**
   ```bash
   git clone https://github.com/inabakumori/ipv6-speedtest-selector.git 
   cd ipv6-speedtest-selector
   ```

3. **Make the script executable:**
   ```bash
   chmod +x ipv6_gen.sh
   ```

4. **Run the script:**
   ```bash
   bash ipv6_gen.sh
   ```

   - The script will ask you how many IPv6 addresses you want to test. Start with a smaller number (like 50) and increase it if needed.
   - The script adds the generated IPv6 addresses to your network interface temporarily for testing. **These addresses will be retained after the script completes.**
   - The script will output a progress bar as it generates and tests the addresses.

5. **The script will create a file named `ipv6.txt`** in the same directory. This file contains the list of generated IPv6 addresses.

### Step 2: Analyze Ping Results and Select the Fastest Addresses (On Your Local Machine)

1. **Transfer the `ipv6.txt` file** from your server to your local machine. You can use `scp`, `ftp`, or any file transfer method you prefer. Make sure to download the `ipv6.py` script as well. 

2. **Open a terminal or command prompt** and navigate to the directory containing both `ipv6.txt` and `ipv6.py` on your local machine. 

3. **Run the Python script:**
   ```bash
   python3 ipv6.py 
   ```
   - This script will ping each IPv6 address in `ipv6.txt` from your local machine and print the 10 fastest addresses with their latencies.

### Step 3:  Making the Fastest Address Permanent (On Your Server)

1. **Choose one of the fastest IPv6 addresses** from the output of the Python script.

2. **On your server**, you'll need to add this address to your network interface configuration. The method depends on how your server manages network settings (e.g., `/etc/network/interfaces`, Netplan).

   **Example using `/etc/network/interfaces`:**

   - Open the file with root privileges (e.g., using `sudo nano /etc/network/interfaces`).
   - Find the section for your network interface (e.g., `eth0`).
   - Add a line to assign the chosen IPv6 address, like this:
     ```
     up ip addr add 2a0c:8a41:5100:0:YOUR_FASTEST_ADDRESS/64 dev eth0
     ```
     (Replace `YOUR_FASTEST_ADDRESS` with the actual IPv6 address you selected.)
   - Save the file and restart your networking service (e.g., `sudo systemctl restart networking`).

3. **Test your connection** to make sure the new IPv6 address is working as expected.

## Important Notes:

* **Network Management Methods:** The example above uses `/etc/network/interfaces`, but your server might use a different method like Netplan. Refer to your server's documentation for how to configure network interfaces. 

* **Persistence Across Reboots:** The added IPv6 addresses from the script are persistent, but if you want the fastest address to be used even after a server reboot, you *must* modify your network configuration files as explained in Step 3.

* **Potential Issues:**  Adding random IPv6 addresses could potentially cause conflicts on your network. It's best to start with a small number of addresses and monitor for any issues. 

## License

This project is licensed under the GNU General Public License v3.0 or later. See the [LICENSE](LICENSE) file for details.
```

I've updated the README to reflect that the Python script will also be on the repository and provided clearer download instructions. Let me know if you have any other questions. 
