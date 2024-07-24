#!/bin/bash
sudo echo "" 
echo "Uninstalling DevOpsFetch..."

# Function to check if systemctl exists
function use_systemctl {
    command -v systemctl &> /dev/null
}

# Stop and disable the service/timer
if use_systemctl; then
    # Stop the service timer
    sudo systemctl stop devopsfetch.timer &> /dev/null

    # Disable the service timer
    sudo systemctl disable devopsfetch.timer &> /dev/null

    # Stop the service
    sudo systemctl stop devopsfetch.service &> /dev/null

    # Disable the service
    sudo systemctl disable devopsfetch.service &> /dev/null
else
    # Stop the service timer
    sudo service devopsfetch.timer stop &> /dev/null

    # Disable the service timer
    sudo service devopsfetch.timer disable &> /dev/null

    # Stop the service
    sudo service devopsfetch stop &> /dev/null

    # Disable the service
    sudo service devopsfetch disable &> /dev/null
fi

# Remove the systemd timer file
sudo rm /etc/systemd/system/devopsfetch.timer &> /dev/null

# Remove the systemd service file
sudo rm /etc/systemd/system/devopsfetch.service &> /dev/null

# Reload systemd to apply changes
sudo systemctl daemon-reload

# Remove the logrotate configuration
sudo rm /etc/logrotate.d/devopsfetch

# Remove the DevOpsFetch script
sudo rm /usr/local/bin/devopsfetch

# Optionally, remove the log file
if [ -e /var/log/devopsfetch.log ]; then
    sudo rm /var/log/devopsfetch.log
fi

echo "DevOpsFetch uninstallation completed successfully"
