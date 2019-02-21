#!/bin/bash

BASEDIR=$(dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )")
source "${BASEDIR}/scripts/functions.sh"

# ------------------------------------------------------------------------------
# Create Cluster
# ------------------------------------------------------------------------------
# In order to create a cluster we need the following:
# Cluster Name, Region, Version, Node Size, Node Count
# ------------------------------------------------------------------------------

# Cluster Name
# TODO: Add validation to this. No empty values, double check if spaces are allowed.
echo -e "\033[33mWhat would you like to name this cluster?\033[39m"
read -p "Cluster name: " CLUSTER_NAME
echo

echo "Fetching Kubernetes information, please wait..."
echo

REGIONS=($(doctl k8s options regions | awk '{if(NR>1)print $1}'))
VERSIONS=($(doctl k8s options versions | awk '{if(NR>1)print $1}'))
NODE_SIZES=($(doctl k8s options sizes | awk '{if(NR>1)print $1}'))

# Cluster Region
echo -e "\033[33mWhat region would you like to use for your cluster?\033[39m"
select_option "${REGIONS[@]}"
choice=$?
CLUSTER_REGION="${REGIONS[$choice]}"

# Kubernetes Version
echo -e "\033[33mWhich version of Kubernetes would you like to use?\033[39m"
select_option "${VERSIONS[@]}"
choice=$?
CLUSTER_VERSION="${VERSIONS[$choice]}"

# Node Size
echo -e "\033[33mPlease specify the node size that you would like to use for this cluster.\033[39m"
select_option "${NODE_SIZES[@]}"
choice=$?
NODE_SIZE="${NODE_SIZES[$choice]}"

# Node Count
echo -e "\033[33mHow many nodes would you like to provision for this cluster?\033[39m"

while true; do
  read -p "Desired node count: " NODE_COUNT
  # Make sure that the entry is a number that is between 1-10.
  if [[ $NODE_COUNT -gt 0 && $NODE_COUNT -lt 11 ]]; then
    break
  else
    echo -e "\033[31mError: Given value is not a valid entry. The count must be from 1 to 10. Please try again.\033[39m"
  fi
done
echo

# Cluster Creation
echo -e "A Kubernetes cluster with the following configuration will be created.\033[39m"
echo "Name: kube-cluster"
echo "Region: nyc1"
echo "Version: 1.13.2-do.0"
echo "Node Size: s-1vcpu-2gb"
echo "Node Count: 1"
echo

echo "Creating a new Kubernetes cluster, please wait a few minutes..."
doctl kubernetes cluster create "${CLUSTER_NAME}" \
  --region "${CLUSTER_REGION}" \
  --version "${CLUSTER_VERSION}" \
  --size "${NODE_SIZE}" \
  --count "${NODE_COUNT}"

if [[ $? -eq 0 ]]; then
  echo -e "\033[32mThe Kubernetes cluster has been successfully created!\033[39m"
else
  echo -e "\033[31mThere was a problem creating the Kubernetes cluster.\033[39m"
  exit 1
fi

# Set the proper context for the cluster.
CLUSTER_CONTEXT="do-${CLUSTER_REGION}-${CLUSTER_NAME}"
kubectl config use-context "${CLUSTER_CONTEXT}" > /dev/null

if [[ $? -eq 0 ]]; then
  echo -e "\033[32mKubectl has been configured to use $CLUSTER_CONTEXT as the default context.\033[39m"
else
  echo -e "\033[31mThere was a problem setting the default context for kubectl.\033[39m"
  exit 1
fi

echo "Please wait until the nodes are up and running..."
until [[ $(kubectl get nodes 2>/dev/null | grep "\sReady\s") ]]; do
  echo -n "."
  sleep 1
done
echo

echo -e "\033[32mKubernetes is up and running!\033[39m"
echo