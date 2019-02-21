#!/bin/bash

BASEDIR=$(dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )")
source "${BASEDIR}/scripts/functions.sh"

# -----------------------------------------------------------------------------
# Copy Config
# -----------------------------------------------------------------------------

echo -e "\033[33mWhich cluster would you like to save the configuration for?\033[39m"

IFS=$'\n'
KUBE_CLUSTERS=($(doctl kubernetes cluster list | awk '{if(NR>1)print $0}'))
unset IFS

select_option "${KUBE_CLUSTERS[@]}"
choice=$?

TARGET_CLUSTER_ID=$(echo ${KUBE_CLUSTERS[$choice]} | awk '{print $1}')
TARGET_CLUSTER_NAME=$(echo ${KUBE_CLUSTERS[$choice]} | awk '{print $2}')
TARGET_CLUSTER_REGION=$(echo ${KUBE_CLUSTERS[$choice]} | awk '{print $3}')
TARGET_CLUSTER_VERSION=$(echo ${KUBE_CLUSTERS[$choice]} | awk '{print $4}')

# Save the config, throwing an error is something unexpected happens.
doctl kubernetes cluster kubeconfig save "${TARGET_CLUSTER_ID}" > /dev/null
if [[ $? -eq 0 ]]; then
  echo -e "\033[32mThe kubeconfig has been successfully saved to $HOME/.kube/config.\033[39m"
else
  echo -e "\033[31mThere was a problem saving the kubeconfig file.\033[39m"
  exit 1
fi
# Set the new context, throwing an error is something unexpected happens.
kubectl config use-context "do-${TARGET_CLUSTER_REGION}-${TARGET_CLUSTER_NAME}" > /dev/null
if [[ $? -eq 0 ]]; then
  echo -e "\033[32mKubectl has been configured to use ${TARGET_CLUSTER_NAME}.\033[39m"
else
  echo -e "\033[31mThere was a problem setting the default context.\033[39m"
  exit 1
fi