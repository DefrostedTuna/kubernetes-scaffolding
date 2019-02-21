#!/bin/bash

set -e

BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
source "${BASEDIR}/scripts/functions.sh"

# Set the backspace key here.
# Create a gif of the script?

# ------------------------------------------------------------------------------
# Welcome
# ------------------------------------------------------------------------------

echo -e "Welcome, this script will help ease the process of setting up a" \
        "Kubernetes cluster from scratch on DigitalOcean."
echo -e "First, we’ll check for any necessary dependencies and install them if necessary."
echo -e "After this you will be guided through each step of the process, being prompted" \
        "for the necessary information needed for configuration."
echo -e "Let’s start by checking those dependencies, here's what we're looking for:"
echo -e "Brew, Kubectl, Helm, and Doctl."
echo

read -p $'\033[33mPress enter to continue...\033[39m'
echo

# ------------------------------------------------------------------------------
# Check Dependencies: Brew, Kubectl, Helm, Doctl.
# ------------------------------------------------------------------------------

"${BASEDIR}"/scripts/dependency-check.sh

# ------------------------------------------------------------------------------
# Create Cluster
# ------------------------------------------------------------------------------

if ask "\033[33mWould you like to create a new Kubernetes cluster?\033[39m"; then
  echo
  "${BASEDIR}"/scripts/create-cluster.sh

else # Copy Config
  echo
  if ask "\033[33mWould you like to save an existing config?\033[39m" Y; then
    echo
    "${BASEDIR}"/scripts/copy-config.sh
  fi
  echo
fi

# ------------------------------------------------------------------------------
# Cluster Initializaton (Helm/Tiller)
# ------------------------------------------------------------------------------

if ask "\033[33mWould you like to initialize Helm/Tiller?\033[39m" Y; then
  echo
  "${BASEDIR}"/scripts/install-helm-tiller.sh
else
  echo
fi

# ------------------------------------------------------------------------------
# Nginx Ingress Setup
# ------------------------------------------------------------------------------

if ask "\033[33mWould you like to install the Nginx Ingress?\033[39m" Y; then
  echo
  "${BASEDIR}"/scripts/install-nginx-ingress.sh
else
  echo
fi

# ------------------------------------------------------------------------------
# Certificate Manager Setup
# ------------------------------------------------------------------------------

if ask "\033[33mWould you like to install Cert Manager?\033[39m" Y; then
  echo
  "${BASEDIR}"/scripts/install-cert-manager.sh
else
  echo
fi

# ------------------------------------------------------------------------------
# Jenkins Setup
# ------------------------------------------------------------------------------

if ask "\033[33mWould you like to install and configure Jenkins?\033[39m" Y; then
  echo
  "${BASEDIR}"/scripts/install-jenkins.sh
else
  echo
fi

# ------------------------------------------------------------------------------
# Harbor Setup
# ------------------------------------------------------------------------------

if ask "\033[33mWould you like to install and configure Harbor?\033[39m" Y; then
  echo
  "${BASEDIR}"/scripts/install-harbor.sh
else
  echo
fi

# ------------------------------------------------------------------------------
# Dashboard Setup
# ------------------------------------------------------------------------------

if ask "\033[33mWould you like to install Kubernetes Dashboard?\033[39m" Y; then
  echo
  "${BASEDIR}"/scripts/install-dashboard.sh
else
  echo
fi