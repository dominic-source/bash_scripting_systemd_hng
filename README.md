# Documentation

## Installation and Configuration

1. Clone the repository:
```bash
cd $HOME
git clone https://github.com/dominic-source/bash_scripting_systemd_hng.git
cd bash_scripting_systemd_hng
```

2. Run the installation script:
```bash
sudo bash install_devopsfetch.sh
```

3. Check the status of the service:
```bash
sudo systemctl status devopsfetch.service
```

## Usage Examples

1. Display all active ports and services:
```bash
devopsfetch -p
```

2. Display detailed information about a specific port:
```bash
devopsfetch -p 80
```

3. List all Docker images and containers:
```bash
devopsfetch -d
```

4. Provide detailed information about a specific container:
```bash
devopsfetch -d container_name
```

5. Display all Nginx domains and their ports:
```bash
devopsfetch -n
```

6. Provide detailed configuration information for a specific domain:
```bash
devopsfetch -n example.com
```

7. List all users and their last login times:
```bash
devopsfetch -u
```

8. Provide detailed information about a specific user:
```bash
devopsfetch -u username
```

## Logging Mechanism
- Logs are stored in /var/log/devopsfetch.log.
- Log rotation and management are configured using logrotate.

## Retrieving logs
*The devopsfetch tool logs its activities to /var/log/devopsfetch.log. You can retrieve and view these logs using various commands:*

1. View logs within a specific time range (the best way):
```bash
devopsfetch -l "YYYY-MM-DD HH:MM:SS" "YYYY-MM-DD HH:MM:SS"
```
*e.g. devopsfetch -l "2024-07-24 20:13:06"  "2024-07-24 20:13:25"*

2. View the entire log file:
```bash
sudo cat /var/log/devopsfetch.log
```

3. View the last 10 lines of the log file:
```bash
sudo tail /var/log/devopsfetch.log
```

4. Follow the log file in real-time:
```bash
sudo tail -f /var/log/devopsfetch.log
```
