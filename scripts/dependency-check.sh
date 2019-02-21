#!/bin/bash

# ------------------------------------------------------------------------------
# Dependency Check
# ------------------------------------------------------------------------------

echo "Checking dependencies..."

# Install Homebrew.
if [ -z $(command -v brew) ]; then
  echo -e "\033[31mHomebrew was not found.\033[39m"
  echo "Installing Homebrew, please wait..."

  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  # Double check that Homebrew was successfully installed.
  # If it was not installed properly, we do not want to continue the script.
  if [ -z $(command -v brew) ]; then
    echo -e "\033[31mThere was an error installing Homebrew." \
            "Homebrew is required to install the remaining dependencies.\033[39m"
    exit 1
  fi
else
  echo "Homebrew is already installed!"
fi

# Install Kubectl.
if [ -z $(command -v kubectl) ]; then
  echo -e "\033[31mKubectl was not found.\033[39m"
  echo "Installing Kubectl, please wait..."

  brew install kubernetes-cli

  # Double check that Kubectl was successfully installed.
  if [ -z $(command -v kubectl) ]; then
    echo -e "\033[31mThere was an error installing Kubectl. Kubectl is" \
            "required to connect to the Kubernetes cluster.\033[39m"
    exit 1
  fi
else
  echo -e "Kubectl is already installed!"
fi

# Install Helm.
if [ -z $(command -v helm) ]; then
  echo -e "\033[31mHelm was not found.\033[39m"
  echo -e "Installing Helm, please wait..."

  brew install kubernetes-helm

  # Double check that Helm was successfully installed.
  if [ -z $(command -v helm) ]; then
    echo -e "\033[31mThere was an error installing Helm. Helm is required to" \
            "install software to the Kubernetes cluster.\033[39m"
    exit 1
  fi
else
  echo -e "Helm is already installed!"
fi

# Install Doctl.
if [ -z $(command -v doctl) ]; then
  echo -e "\033[31mDoctl was not found.\033[39m"
  echo -e "Installing Doctl, please wait..."

  brew install doctl

  # Double check that Doctl was successfully installed.
  if [ -z $(command -v doctl) ]; then
    echo -e "\033[31mThere was an error installing Doctl." \
            "Doctl is required to interact with DigitalOcean.\033[39m"
    exit 1
  fi
else
  echo -e "Doctl is already installed!"
fi

if [[ -z $(doctl auth init 2>/dev/null | grep "Validating token... OK") ]]; then
  echo -e "\033[31mAn access token for doctl was not found.\033[39m"
  echo "In order to interact with DigitalOcean, doctl must authenticate using an access token."
  echo "This token can be created via the Applicatons & API section of the DigitalOcean Control Panel."
  echo "https://cloud.digitalocean.com/account/api/tokens"
  echo "Please note that this token must have both read and write access."
  echo

  while true; do
    echo -e "\033[33mPlease provide your DigitalOcean API Token\033[39m: "
    read DO_TOKEN

    doctl auth init -t "${DO_TOKEN}" > /dev/null 2>&1

    if [[ $? -eq 0 ]]; then
      echo "\033[32mToken is valid! Doctl can now communicate with DigitalOcean!\033[39m"
      break
    else
      echo -e "\033[31mThere was an error authenticating with DigitalOcean. Please try again.\033[39m"
    fi
  done
fi
echo