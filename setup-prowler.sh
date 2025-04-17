#!/bin/bash

set -e 

echo "Updating system and installing dependecies..."
sudo apt update && sudo apt install -y \
    ca-certificates \
    curl \ 
    gnupg \
    lsb-release \
    unzip \

echo "Installing Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL  https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyring/docker.gpg

echo \
      "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Enabling Docker service and adding current user to docker group..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker "$USER"

echo "Creating directory structure..."
mkdir -p ~/prowler/output

echo "Creating run-prowler.sh script..."
cat << 'EOF' > ~/prowler/run-prowler.sh
#!/bin/bash

OUTPUT_DIR="$(pwd)/output"
mkdir -p "$OUTPUT_DIR"

docker run --rm -it \
    -v "$HOME/.aws":root/.aws:ro \
    -v "$OUTPUT_DIR":/prowler/output \
    -e AWS_PROFILE=auditor \ 
    ghcr.io/prowler-cloud/prowler:latest \
    -M html,csv,json \
    -S
EOF

chmod +x ~/prowler/run-prowler.sh

echo "Setup complete!"
echo "Reboot your system, and Then run: ~/prowler/run-prowler.sh"
