#!/bin/bash

# ------------------------------------------------------------------------------
# Cluster Initializaton (Helm/Tiller)
# ------------------------------------------------------------------------------

# Install the Service Accounts and RBAC for Helm/Tiller.
# Follow up by initializing Helm/Tiller on the cluster.
echo "Setting up resources and initializing Helm/Tiller..."
kubectl -n kube-system create serviceaccount tiller > /dev/null 2>&1
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller > /dev/null 2>&1
helm init --service-account tiller > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
  echo -e "\033[32mTiller has been initialized!\033[39m"
else
  echo -e "\033[31mThere was a problem intializing Tiller.\033[39m"
  exit 1
fi

# Wait for Tiller to spin up before continuing to install software.
echo "Please wait while the tiller pod comes online..."
until [[ $(kubectl get pods -n kube-system 2> /dev/null | grep tiller | awk -F " " '{print $2}' | awk -F "/" '{print $1}') -ge "1" ]]; do
  echo -n "."
  sleep 1
done
echo

echo -e "\033[32mTiller is up and running!\033[39m"
echo