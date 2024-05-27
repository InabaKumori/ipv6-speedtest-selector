import subprocess
import re
from collections import defaultdict

def ping_addresses(filename="ipv6.txt"):
  """Pings IPv6 addresses from a file and returns the 10 with lowest latency.

  Args:
    filename: The name of the file containing the IPv6 addresses.

  Returns:
    A list of the 10 IPv6 addresses with the lowest latency.
  """
  ip_addresses = []
  with open(filename, 'r') as f:
    for line in f:
      match = re.search(r'inet6\s+([0-9a-f:]+)', line)
      if match:
        ip_addresses.append(match.group(1))

  latencies = defaultdict(list)
  for ip in ip_addresses:
    try:
        # Ping command (adjust count as needed)
        ping = subprocess.Popen(["ping", "-c", "4", "-W", "2", ip], 
                                stdout=subprocess.PIPE, 
                                stderr=subprocess.PIPE)
        out, err = ping.communicate()
        # Extract latency from output (adjust regex if needed)
        match = re.search(r'rtt min/avg/max/mdev = ([\d\.]+)/', out.decode('utf-8'))
        if match:
          latency = float(match.group(1))
          latencies[ip] = latency
          print(f"{ip}: {latency:.2f} ms")
        else:
          print(f"{ip}: Request timed out")
    except Exception as e:
        print(f"{ip}: Error - {e}")
  
  # Sort by latency and get top 10
  sorted_latencies = sorted(latencies.items(), key=lambda item: item[1])
  top_10 = sorted_latencies[:10]

  print("\nTop 10 Addresses with Lowest Latency:")
  for ip, latency in top_10:
    print(f"{ip}: {latency:.2f} ms")

  return top_10

# Call the function
top_10_addresses = ping_addresses()
