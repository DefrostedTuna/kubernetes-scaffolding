#!/bin/bash

# ------------------------------------------------------------------------------
# Nginx Ingress Setup
# ------------------------------------------------------------------------------

# This will also set up a load balancer on the DigitalOcean account.
echo "Installing Nginx Ingress..."
echo -e "\033[31mThis will by association create a Load Balancer on the" \
        "associated DigitalOcean acount.\033[39m"
helm upgrade --install nginx-ingress --namespace nginx-ingress stable/nginx-ingress > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
  echo -e "\033[32mNginx Ingress has been installed successfully!\033[39m"
else
  echo -e "\033[31mThere was a problem installing the Nginx Ingress.\033[39m"
  exit 1
fi

# Wait for the Ingress to come online before continuing.
echo "Please wait while the Ingress pod comes online..."
until [[ $(kubectl get pods -n nginx-ingress 2> /dev/null | grep ingress-controller | awk -F " " '{print $2}' | awk -F "/" '{print $1}') -ge "1" ]]; do
  echo -n "."
  sleep 1
done
echo # For newline.

echo -e "\033[32mNginx Ingress is up and running!\033[39m"
echo