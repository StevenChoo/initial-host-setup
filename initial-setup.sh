#!/usr/bin/env bash

PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC61LLzlNPuNwwn\
PXriJ0uDuY1GQbTGkc1ZMYIkTTUnEhOxo8ioaXqtuvG86wOZMoAYOWCrASHVoisL\
kSLD6wpIDcjrHn6e0+7cwGetys64a/9pSV9a1UMdU4wSiYH8gy1YHo9SPFvpTkhc\
26XyWhH+rfBhl5x/BBJOEN+ycJJAL5WUwkp37INAoBGfPF+Y7qQJi7N9uw0NFTMT/\
MYrbm6YLDAKvIv/cxeCNlVT3Cjn3ZKJh+JFoz0FXp1W35sxSGEDYyIz8eS2JRBHar\
5TsK430+oP9fZyU9jqlnrhiYJ2vLZ0cSq2lTpUITmvmkMkB+jao/9cqE9B9aXq+hdnj8Ip"

USERNAME=""
PASSWORD=""

function on_exit {
    trap - 0 1 2 3 15
    unset USERNAME
    unset PASSWORD
    echo "Cleaning up and exiting! exitcode=${?}"
}

trap on_exit 0 1 2 3 15 # EXIT SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM

root_check() {
    if [[ $EUID -ne 0 ]]; then
       echo "This script must be run as root"
       exit 1
    fi
}

string_check() {
    INPUT="$1"
    MESSAGE="$2"
    if [[ -z "$MESSAGE" ]]; then
       MESSAGE="Arg: $1 is not or an empty String. Invalid arg given."
    fi
    # replace empty spaces
    if [[ -z "${INPUT// }" ]]; then
        clear
        echo "$MESSAGE"
        exit 1
    fi
}

show_password_dialog() {

    TITLE1="Set your password"
    MESSAGE1="Give the desired password"

    TITLE2="Verify your password"
    MESSAGE2="Type again to verify password"

    TITLE3="Passwords not matching"
    MESSAGE3="Passwords do no match. Do you want to try again?"

    PASSWORD1=$(dialog --stdout --title "${TITLE1}" --clear --insecure --passwordbox "${MESSAGE1}" 8 60)
    PASSWORD2=$(dialog --stdout --title "${TITLE2}" --clear --insecure --passwordbox "${MESSAGE2}" 8 60)

    if [[ -z "${PASSWORD1// }" ]] || [ "$PASSWORD1" != "$PASSWORD2" ]; then

        ANSWER=$(dialog --stdout --clear --title "Retry"  --yesno "Do you want to retry?" 0 0)

        if [[ ${ANSWER} -eq 0 ]]; then
            echo $(show_password_dialog)
        else
            echo ""
            exit 1
        fi
    else
      echo "$PASSWORD1"
    fi
}

show_input_dialog() {
    string_check "${1}" "Unable to create dialog. Title cannot be empty"
    string_check "${2}" "Unable to create dialog. Type and options cannot be empty"

    MESSAGE="$3"
    if [[ -z "${MESSAGE}" ]]; then
       MESSAGE="Unable to get input."
    fi

    RESULT=$(dialog --stdout --title "${1}" --clear --inputbox "${2}" 8 60)

    # Does not work in a subshell. Using subshell to return result
    #
    #EXITCODE=$?
    #if [ ${EXITCODE} -eq 1 ]; then
    #    clear
    #    echo "Cancel pressed. ${MESSAGE} Exiting!"
    #    exit 1
    #elif [ ${EXITCODE} -eq 255 ]; then
    #    clear
    #    echo "[ESC] key pressed. ${MESSAGE} Exiting!"
    #   exit 1
    #fi
    echo "$RESULT"
}

# Check if run as root
root_check

# update apt and install dependencies (silently)
clear
echo "Installing dependencies..."
# Avoiding error: debconf: delaying package configuration, since apt-utils is not installed by installing apt-utils
apt-get update 1>/dev/null && apt-get install -y --no-install-recommends apt-utils 1>/dev/null && apt-get -y install dialog 1>/dev/null

# Get the username
USERNAME=$(show_input_dialog "Set default username" "Give the desired username")
string_check "$USERNAME" "No username chosen. Unable to run script!"

# Get the userid
PASSWORD=$(show_password_dialog)
string_check "$PASSWORD" "No valid password chosen. Unable to run script!"

## Installing desired functionalities
clear
echo "Installing sudo and ssh..."
apt-get update 1>/dev/null && apt-get -y install ssh sudo 1>/dev/null

## Check if user exists. If not create a new one with given user id
if [[ -z "${EXISTING_USERNAME// }" ]]; then
   echo "Adding user: $USERNAME..."
   useradd --create-home --shell /bin/bash --groups sudo "$USERNAME"
fi

echo "Updating password of user..."
echo "$USERNAME:$PASSWORD" | chpasswd

echo "Adding public key..."
su -c "mkdir ~/.ssh" "$USERNAME"
su -c "echo $PUBLIC_KEY > ~/.ssh/authorized_keys" "$USERNAME"
su -c "chmod 700 ~/.ssh" "$USERNAME"
su -c "chmod 600 ~/.ssh/authorized_keys" "$USERNAME"

echo "Finished initial setup for: $HOSTNAME with ip addresses: $(hostname --all-ip-addresses)"
read -n 1 -s -r -p "Press any key to reboot"
shutdown -r now
