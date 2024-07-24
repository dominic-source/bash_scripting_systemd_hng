#!/bin/bash
set -e

# Install necessary dependencies
sudo echo ""
echo "Installing dependences"
# sudo apt-get update
if ! command -v docker &> /dev/null; then
    sudo apt-get install -y docker.io
fi

if ! command -v nginx &> /dev/null; then
    sudo apt-get install -y nginx
fi

if ! command -v logrotate &> /dev/null; then
    sudo apt-get install -y logrotate
fi

if ! command -v ss &> /dev/null; then
    sudo apt-get install -y ss
fi

# Copy devopsfetch script to /usr/local/bin and make it executable
chmod +x devopsfetch.sh
sudo cp devopsfetch.sh /usr/local/bin/devopsfetch

# Check if the script is copied
if [ -e /usr/local/bin/devopsfetch ]; then
    echo "DevOpsFetch script copied to /usr/local/bin"
else
    echo "Failed to copy DevOpsFetch script to /usr/local/bin"
    exit 1
fi

# Check if the script is executable
if [ -x /usr/local/bin/devopsfetch ]; then
    echo "DevOpsFetch script is executable"
else
    echo "Failed to make DevOpsFetch script executable"
    exit 1
fi


# Create systemd service file
# /etc/systemd/system/devopsfetch.service
sudo tee /etc/systemd/system/devopsfetch.service > /dev/null <<EOL
[Unit]
Description=DevOpsFetch Service

[Service]
ExecStart=/usr/local/bin/devopsfetch
StandardOutput=append:/var/log/devopsfetch.log
StandardError=append:/var/log/devopsfetch.log
EOL

# /etc/systemd/system/devopsfetch.timer
sudo tee /etc/systemd/system/devopsfetch.timer > /dev/null <<EOL
[Unit]
Description=Run DevOpsFetch every 1 minutes

[Timer]
OnCalendar=*:0/1
Persistent=true

[Install]
WantedBy=timers.target
EOL

# Create logrotate configuration
sudo tee /etc/logrotate.d/devopsfetch > /dev/null <<EOL
/var/log/devopsfetch.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 root utmp
    sharedscripts
    postrotate
        systemctl reload devopsfetch.service > /dev/null
    endscript
}
EOL

# Reload systemd and start the service
sudo systemctl daemon-reload
sudo systemctl start devopsfetch.service &> /dev/null
sudo systemctl enable devopsfetch.service &> /dev/null
sudo systemctl enable devopsfetch.timer &> /dev/null
sudo systemctl start devopsfetch.timer &> /dev/null

echo "DevOpsFetch installation completed successfully"