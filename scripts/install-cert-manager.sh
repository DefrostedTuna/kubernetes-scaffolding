#!/bin/bash

BASEDIR=$(dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )")
source "${BASEDIR}/scripts/functions.sh"

# -----------------------------------------------------------------------------
# Install Cert Manager
# -----------------------------------------------------------------------------

echo "Installing Cert Manager please wait..."
helm upgrade --install cert-manager --namespace kube-system stable/cert-manager > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
  echo -e "\033[32mCert Manager has been installed successfully!\033[39m"
else
  echo -e "\033[31mThere was a problem installing Cert Manager.\033[39m"
  exit 1
fi

# Wait for the Certificate Manager to come online before trying to create any Cluster Issuers.
echo "Please wait while the Cert Manager pod comes online..."
until [[ $(kubectl get pods -n kube-system 2> /dev/null | grep cert-manager | awk -F " " '{print $2}' | awk -F "/" '{print $1}') -ge "1" ]]; do
  echo -n "."
  sleep 1
done
echo

echo -e "\033[32mCert Manager is up and running!\033[39m"
echo

echo -en "\033[33mPlease enter your email address\033[39m: "
read EMAIL
echo

sed -E 's/\[EMAIL\]/'"$EMAIL"'/' \
  "${BASEDIR}"/templates/cluster-issuers.yaml > "${BASEDIR}"/files/cluster-issuers.yaml

echo "Configuring default Cluster Issuers for staging and production..."
kubectl apply -f "${BASEDIR}"/files/cluster-issuers.yaml > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
  echo -e "\033[32mCluster Issuers have been successfully configured!\033[39m"
else
  echo -e "\033[31mThere was a problem configuring the Cluster Issuers.\033[39m"
  exit 1
fi
echo