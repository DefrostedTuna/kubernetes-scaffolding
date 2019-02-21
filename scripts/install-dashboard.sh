#!/bin/bash

BASEDIR=$(dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )")
source "${BASEDIR}/scripts/functions.sh"

# -----------------------------------------------------------------------------
# Install Kubernetes Dashboard
# -----------------------------------------------------------------------------

echo "Kubernetes Dashboard will now be installed onto the cluster."
echo "Please note that the dashboard cannot be accessed via an external URL."
echo "In order to access the dashboard a proxy will need to be opened on the cluster."

echo "Setting up an access token..."

cp "${BASEDIR}"/templates/dashboard-auth.yaml "${BASEDIR}"/files/dashboard-auth.yaml > /dev/null 2>&1
kubectl apply -f "${BASEDIR}"/files/dashboard-auth.yaml > /dev/null 2>&1
ACCESS_TOKEN=$(kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') | grep 'token:' | awk -F " " '{print $2}')

if [[ $? -eq 0 ]]; then
  echo -e "\033[32mAccess token successfully created!\033[39m"
else
  echo -e "\033[31mThere was a problem creating the dashboard access token.\033[39m"
fi

echo "Installing Kubernetes Dashboard..."

helm upgrade --install kubernetes-dashboard --namespace kube-system  stable/kubernetes-dashboard --set fullnameOverride="kubernetes-dashboard" > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
  echo -e "\033[32mKubernetes Dashboard has been successfully installed!\033[39m"
else
  echo -e "\033[31mThere was a problem installing Kubernetes Dashboard.\033[39m"
  exit 1
fi

echo "Please wait while the Kubernetes Dashboard pod come online..."
until [[ $(kubectl get pods -n kube-system 2> /dev/null | grep kubernetes-dashboard | awk -F " " '{print $2}' | awk -F "/" '{print $1}') -ge "1" ]]; do
  echo -n "."
  sleep 1
done;
echo

echo -e "\033[32mKubernetes Dashboard is up and running!\033[39m"
echo

echo -e "\033[33mTo access the dashboard, you must run the following command in a terminal window:\033[39m"
echo "kubectl proxy"
echo -e "\033[33mOnce the proxy has been opened, the dashboard may be accessed via\033[39m:"
echo "http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:https/proxy/"
echo -e "\033[33mThe following access token can be used to log in to the dashboard\033[39m:" 
echo "${ACCESS_TOKEN}"