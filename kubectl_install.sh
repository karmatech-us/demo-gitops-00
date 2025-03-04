#!/bin/bash

# filepath: /home/iyusuf/projects/automation-ansible-bash/bash-tools/kubectl_install.sh

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check the success of the last command
check_success() {
    if [ $? -eq 0 ]; then
        echo "$1 succeeded."
    else
        echo "$1 failed."
        exit 1
    fi
}

# Function to install kubectl
install_kubectl() {
    if command_exists kubectl; then
        echo "kubectl is already installed."
    else
        echo "Installing kubectl..."

        # Download the latest release of kubectl
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        check_success "Downloading kubectl"

        # Install kubectl
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        check_success "Installing kubectl"

        # Verify kubectl installation
        if command_exists kubectl; then
            echo "kubectl installed successfully! Version: $(kubectl version --client --short)"
        else
            echo "kubectl installation failed. Please check the logs."
            exit 1
        fi
    fi
}

# Main script execution
install_kubectl