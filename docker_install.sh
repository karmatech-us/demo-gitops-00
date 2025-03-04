#!/bin/bash

# filepath: /home/iyusuf/projects/automation-ansible-bash/laptop/bash/dockerengine_install.sh

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

# Function to install Docker Engine
install_docker_engine() {
    echo "Starting Docker Engine installation..."

    # Download Docker GPG key
    echo "Downloading Docker GPG key..."
    sudo mkdir -p /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    check_success "Downloading Docker GPG key"

    # Set permissions for the GPG key
    echo "Setting permissions for Docker GPG key..."
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    check_success "Setting permissions for Docker GPG key"

    # Add Docker repository
    echo "Adding Docker repository to Apt sources..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    check_success "Adding Docker repository"

    # Update package index again
    echo "Updating package index for Docker repository..."
    sudo apt-get update
    check_success "apt-get update for Docker repository"

    # Install Docker packages
    echo "Installing Docker packages..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    check_success "Installing Docker packages"

    # Verify installation
    echo "Verifying Docker Engine installation..."
    sudo docker run hello-world || echo "Docker Engine verification completed (but hello-world might not run as expected)."
    
    echo "Docker Engine installation completed successfully!"
}

# Function to install Docker Compose
install_docker_compose() {
    if command_exists docker-compose; then
        echo "Docker Compose is already installed."
    else
        echo "Installing Docker Compose..."

        # Download Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        check_success "Downloading Docker Compose"

        # Apply executable permissions to the binary
        sudo chmod +x /usr/local/bin/docker-compose
        check_success "Setting executable permissions for Docker Compose"

        # Verify Docker Compose installation
        if command_exists docker-compose; then
            echo "Docker Compose installed successfully! Version: $(docker-compose --version)"
        else
            echo "Docker Compose installation failed. Please check the logs."
            exit 1
        fi
    fi
}

# Main script execution
install_docker_engine
install_docker_compose