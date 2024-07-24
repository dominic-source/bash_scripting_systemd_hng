#!/bin/bash

# Develop a tool for devops named devopsfetch that collects and
# displays system information, including active ports,
# user logins, Nginx configurations, Docker images,
# and container statuses. Implement a systemd service to
# monitor and log these activities continuously.

# user must use sudo to run the script
# if [ $(id -u) -ne 0 ]; then
#     echo "Please run as root"
#     exit
# fi

sudo echo ""
info_output() {
    echo "Usage: devopsfetch [-p | --port] [-d | --docker] [-n | --nginx] [-u | --users] [-t | --time]"
}

LOG_FILE="/var/log/devopsfetch.log"

date_to_timestamp() {
    date -d "$1" '+%s'
}

list_all_active_ports_service() {
    printf "%-20s %-20s %-20s\n" "USER" "PORT" "SERVICE"
    sudo ss -tulwnp | tail -n +2 | while read -r line; do
        port=$(echo "$line" | sed -E 's/.*[:[]([0-9]+).*/\1/')
        service=$(echo "$line" | sed -n 's/.*users:(("\([^"]*\).*/\1/p')
        pid=$(echo "$line" | sed -n 's/.*pid=\([0-9]*\).*/\1/p')
        user=$(ps -o user= -p "$pid")
        printf "%-20s %-20s %-20s\n" "$user" "$port" "$service"
    done
}

list_all_docker_images_containers() {
    docker ps -a
    docker images
}

list_all_nginx_domains_ports() {
    printf "%-20s %-20s %-20s\n" "NGINX DOMAIN" "PORT" "PROXY"
    sudo nginx -T 2>&1 | grep -P 'server_name|listen|proxy_pass' | grep -vP '^\s*#' | tac | while read -r line; do
        if [[ $line =~ proxy_pass ]]; then
            proxy=$(echo $line | awk '{print$2}' | tr -d ';')
        elif [[ $line =~ server_name ]]; then
            domain=$(echo $line | awk '{print $2}' | tr -d ';')
        elif [[ $line =~ listen ]]; then
            port=$(echo $line | awk '{print $2}' | tr -d ';')
            printf "%-20s %-20s %-20s\n" "$domain" "$port" "$proxy"
        fi
    done
}

list_all_users_login__times() {
    printf "%-20s %-20s %-20s %-20s\n" "USER" "LAST LOGIN" "LOGIN TIME" "TERMINAL"
    getent passwd | cut -d: -f1 | while read -r user; do
        read login_date login_time duration terminal <<< $(last -w -n 1 $user | awk -v user="$user" '$1 == user { print $5, $6, $7, $2 $NF }')
        if [ -z "$login_date" ]; then
            login="Never logged in"
            terminal="N/A"
            duration="N/A"
            if [[ -n "$1" && "$1" = "--filter" ]]; then
                continue
            fi
        else
            # Convert to YYYY-MM-DD format
            login=$(date -d "$login_date $login_time" '+%Y-%m-%d' 2>/dev/null)
            if [ -z "$login" ]; then
                login="Date conversion error"
                terminal="N/A"
                duration="N/A"
            fi
        fi
        printf "%-20s %-20s %-20s %-20s\n" "$user" "$login" "$duration" "$terminal"
    done
}


# display all active ports and services
if [ "$1" = "-p" ] || [ "$1" = "--port" ]; then
    if [ "$2" ]; then
        list_all_active_ports_service | grep "$2 "
        exit 0
    else
        list_all_active_ports_service
        exit 0
    fi

# list all docker images and containers
elif [ "$1" = "-d" ] || [ "$1" = "--docker" ]; then

    if [ "$2" ]; then
        # provide detailed information about a specific container
        sudo docker inspect $2
        exit 0
    else
        list_all_docker_images_containers
        exit 0
    fi

# Display all Nginx domains and their ports (-n or --nginx).
elif [ "$1" = "-n" ] || [ "$1" = "--nginx" ]; then

    if [ "$2" ]; then
        # provide detailed configuration information for a specific domain
        sudo nginx -T 2>&1 | awk -v domain="$2" '
        BEGIN { found = 0 }
        /server_name.*'$2'/ { found = 1 }
        found { print }
        /}/ { if (found) { found = 0; exit } }
        '
        exit
    else
        list_all_nginx_domains_ports
        exit 0
    fi

# Check for user last login times
elif [ "$1" = "-u" ] || [ "$1" = "--users" ]; then
    if [ "$2" ]; then
        # provide detailed information about a specific user
        
        username="$2"

        # Fetch user details
        user_id=$(id -u $username)
        group_id=$(id -g $username)
        groups=$(id -Gn $username)
        home_directory=$(getent passwd $username | cut -d: -f6)
        shell=$(getent passwd $username | cut -d: -f7)
        last_login=$(last -w -n 1 $username | awk '{print $4, $5, $6, $7}')

        # Check if user exists
        if [ -z "$user_id" ]; then
            echo "User $username does not exist."
            exit 1
        fi

        # Display the information in a table format
        echo "User Information for: $username"
        printf "%-20s | %-50s\n" "Attribute" "Value"
        printf "%-20s | %-50s\n" "------------------" "--------------------------------------------------"
        printf "%-20s | %-50s\n" "User ID" "$user_id"
        printf "%-20s | %-50s\n" "Group ID" "$group_id"
        printf "%-20s | %-50s\n" "Groups" "$groups"
        printf "%-20s | %-50s\n" "Home Directory" "$home_directory"
        printf "%-20s | %-50s\n" "Shell" "$shell"
        printf "%-20s | %-50s\n" "Last Login" "$last_login"

        exit 0

    else
       list_all_users_login__times
    fi

# Implement a help flag -h or --help to provide usage instructions for the program.
elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: devopsfetch [OPTION]..."
    echo "Collect and display system information."
    echo
    echo "Options:"
    echo "  -p, --port [PORT_NUMBER]     Display all active ports or detailed information about a specific port."
    echo "  -d, --docker [CONTAINER]     List all Docker images and containers or provide detailed information about a specific container."
    echo "  -n, --nginx [DOMAIN]         Display all Nginx domains and their ports or provide detailed configuration information for a specific domain."
    echo "  -u, --users [USERNAME]       List all users and their last login times or provide detailed information about a specific user."
    echo "  -t, --time  [FORMAT]         Display activities within a specified time range. format 'YYYY-MM-DD HH:MM:SS'"
    echo "  -h, --help                   Display this help and exit."
    exit 0
elif [ "$1" = "-t" ] || [ "$1" = "--time" ]; then
    # Display activities within a specified time range
    if [ "$2" ] && [ "$3" ]; then
        # Extract start and end dates
        start_time="$2"
        end_time="$3"

        # Convert dates to timestamps
        start_timestamp=$(date_to_timestamp "$start_time")
        end_timestamp=$(date_to_timestamp "$end_time")

        # Check if the timestamps are valid
        if [ -z "$start_timestamp" ] || [ -z "$end_timestamp" ]; then
            echo 'Invalid date format. Please use "YYYY-MM-DD HH:MM:SS" "YYYY-MM-DD HH:MM:SS".'
            exit 1
        fi

        # Filter logs between the start and end timestamps
        awk -v start="$start_timestamp" -v end="$end_timestamp" '
        {
            # Convert log date to timestamp
            gsub(/[-:]/, " ", $1)
            gsub(/[-:]/, " ", $2)
            log_timestamp = mktime($1 " " $2)
            if (log_timestamp >= start && log_timestamp <= end) {
                print $0
                while (getline > 0 && $0 !~ /^[0-9]{4}[- ][0-9]{2}[- ][0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/) {
                    print $0
                }
            }
        }' "$LOG_FILE"
        exit 0
    else
        info_output
        echo "Please provide a start and end time in the format: YYYY-MM-DD HH:MM:SS."
        exit 0
    fi
fi

# Logging mechanism
{
    date '+%Y-%m-%d %H:%M:%S'
    echo
    list_all_active_ports_service
    echo
    list_all_docker_images_containers
    echo
    list_all_nginx_domains_ports
    echo
    list_all_users_login__times "--filter"
    echo -e "\n"
} | sudo tee -a $LOG_FILE > /dev/null
