#!/bin/bash

BASEDIR=$(dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )")
source "${BASEDIR}/scripts/functions.sh"

# -----------------------------------------------------------------------------
# Install Jenkins
# -----------------------------------------------------------------------------
# When installing Jenkins, we want to first check if there is an existing
# Block Storage Volume available. If there is, we'll use that, otherwise
# we want to create a new volume. Once the volume is present, we can move
# on to setting up the PV/PVC for Jenkins, and finally installing the
# Jenkins instance itself on the Kubernetes cluster.
# -----------------------------------------------------------------------------

echo "Jenkins will now be installed onto the Kubernetes cluster."
echo

# Check for existing volume
if ask "\033[33mUse existing Block Storage Volume for Jenkins?\033[39m"; then
  echo
  echo -e "\033[33mWhich volume will be used for Jenkins?\033[39m"

  # Retrieve the list of volumes in DigitalOcean.
  IFS=$'\n'
  VOLUME_LIST=($(doctl compute volume list | awk '{if(NR>1)printf("%s  %-40s  %s %s  %s\n", $1, $2, $3, $4, $5)}'))
  unset IFS

  select_option "${VOLUME_LIST[@]}"
  choice=$?

  VOLUME_ID=$(echo ${VOLUME_LIST[$choice]} | awk '{print $1}')
  VOLUME_NAME=$(echo ${VOLUME_LIST[$choice]} | awk '{print $2}')
  VOLUME_SIZE=$(echo ${VOLUME_LIST[$choice]} | awk '{print $3}')
else # No existing volume is being used.
  echo

  # Create new volume in DigitalOcean
  echo "Gathering cluster information, please wait..."
  
  # General volume info.
  VOLUME_NAME="pvc-jenkins"
  VOLUME_SIZE="5" # In gigabytes.

  # This is a bit cumbersome, but it will ultimately be fairly reliable.
  CLUSTER_ID=$(kubectl cluster-info | \
    grep -om 1 "\(https://\)\([^.]\+\)" | \
    awk -F "//" '{print $2}')
  CLUSTER_NAME=$(doctl kubernetes cluster get "${CLUSTER_ID}" | \
    awk '{if(NR>1)print $2}')
  CLUSTER_REGION=$(doctl kubernetes cluster get "${CLUSTER_ID}" | \
    awk '{if(NR>1)print $3}')

  echo "Creating a ${VOLUME_SIZE}GB Block Storage Volume named ${VOLUME_NAME} in" \
    "the ${CLUSTER_REGION} region. Please wait..."

  CREATE_VOLUME_OUTPUT=$(doctl compute volume create "${VOLUME_NAME}" \
	  --region ${CLUSTER_REGION} \
  	--fs-type ext4 \
	  --size ${VOLUME_SIZE}GiB)

  if [[ $? -eq 0 ]]; then
    echo -e  "\033[32mVolume successfully created!\033[39m"
  else
    echo -e "\033[31mThere was a problem creating the volume.\033[39m"
    exit 1
  fi

  # Volume ID can only be found after creation.
  VOLUME_ID=$(echo "${CREATE_VOLUME_OUTPUT}" | awk '{if(NR>1)print $1}')
fi;

# Create the PV/PVC
echo "Attaching volume ${VOLUME_NAME} to the Kubernetes cluster..."

# Set all of the values for the new/existing DigitalOcean Volume and apply the config.
sed -E 's/\[VOLUME_NAME]/'"${VOLUME_NAME}"'/;s/\[VOLUME_SIZE]/'"${VOLUME_SIZE}Gi"'/;s/\[VOLUME_ID]/'"${VOLUME_ID}"'/' \
  "${BASEDIR}"/templates/pvc-jenkins.yaml > "${BASEDIR}"/files/pvc-jenkins.yaml
kubectl apply -f "${BASEDIR}"/files/pvc-jenkins.yaml > /dev/null

if [[ $? -eq 0 ]]; then
  echo -e "\033[32mVolume successfully attached to Kubernetes!\033[39m"
else
  echo -e "\033[31mThere was a problem attching the volume.\033[39m"
fi
echo

# Create a DNS record
if ask "\033[33mWould you like to create a DNS record for Jenkins?\033[39m"; then
  echo
  echo -e "\033[33mWhich domain will Jenkins be hosted on?\033[39m"

  VALID_DOMAINS=($(doctl compute domain list | awk '{if(NR>1)print $1}'))
  
  select_option "${VALID_DOMAINS[@]}"
  choice=$?
  DOMAIN_NAME="${VALID_DOMAINS[$choice]}"

  # Validate FDQN with domain name.
  echo -en "\033[33mWhat is the FQDN that Jenkins will be hosted from?\033[39m "
  echo -e "(Example: https://jenkins.dev.example.com)"
  while true; do
    read -p "Jenkins domain name: https://" JENKINS_FQDN
    # Strip out 'http://' and 'https://' just in case.
    JENKINS_FQDN=$(echo "${JENKINS_FQDN}" | sed -e 's/http[s]\{0,1\}:\/\///g')

    if [[ -z $(echo "${JENKINS_FQDN}" | grep ".*${DOMAIN_NAME}$") ]]; then
      echo -e "\033[31mThe FQDN does not match the domain name.\033[39m"
    else
      break
    fi;
  done;
  echo

  # Get record name minus the domain name.
  DNS_RECORD_NAME=$(echo "${JENKINS_FQDN}" | sed 's/.'"${DOMAIN_NAME}"'//g')

  # Load Balancer IP validation.
  echo "Fetching load balancer information, please wait..."
  echo

  KUBE_LB=($(kubectl get svc --all-namespaces | grep LoadBalancer | awk '{print $5}'))
  DO_LB=($(doctl compute load-balancer list | awk '{if(NR>1)print $2}'))

  # Make sure that the load balancers in Kubernetes 
  # match the ones present in DigitalOcean.
  MATCHING=()
  for i in $KUBE_LB; do
    for k in $DO_LB; do
      if [[ "$i" == "$k" ]]; then
        MATCHING+=("$i")
      fi
    done
  done

  if [[ "${#MATCHING[@]}" -gt 1 ]]; then
    echo "Multiple load balancers were found. Please choose the desired load balancer to be used."
    
    select_option "${MATCHING[@]}"
    choice=$?
    LOAD_BALANCER_IP="${MATCHING[$choice]}"
  else
    LOAD_BALANCER_IP="${MATCHING}" # Since there will only be one.
  fi

  echo "A DNS record for Jenkins will be created with the following information."
  echo "Domain: ${DOMAIN_NAME}"
  echo "Record: ${DNS_RECORD_NAME}"
  echo "Bound Load Balancer IP: ${LOAD_BALANCER_IP}"
  echo

  echo "Creating DNS record..."
  # DNS_RECORD_NAME
  # LOAD_BALANCER_IP
  doctl compute domain records create "${DOMAIN_NAME}" \
    --record-type A \
    --record-name "${DNS_RECORD_NAME}" \
    --record-data "${LOAD_BALANCER_IP}" \
    --record-priority 0 \
    --record-ttl 1800 \
    --record-weight 0 > /dev/null

  if [[ $? -eq 0 ]]; then
    echo -e "\033[32mDNS record successfully created!\033[39m"
  else
    echo -e "\033[31mThere was a problem creating the DNS record.\033[39m"
  fi
else
  echo
  echo -en "\033[33mWhat is the FQDN that Jenkins will be hosted from?\033[39m "
  echo -e "(Example: https://jenkins.dev.example.com)"
  read -p "Jenkins domain name: https://" JENKINS_FQDN
  # Strip out 'http://' and 'https://'.
  JENKINS_FQDN=$(echo "${JENKINS_FQDN}" | sed -e 's/http[s]\{0,1\}:\/\///g')
fi
echo

# Configure Jenkins values.
echo "Configuring Jenkins..."
sed -E 's/\[HOSTNAME]/'"${JENKINS_FQDN}"'/;s/\[PVC_NAME]/'"${VOLUME_NAME}"'/' \
  "${BASEDIR}"/templates/jenkins-values.yaml > "${BASEDIR}"/files/jenkins-values.yaml

# Install Jenkins (Finally)
echo "Installing Jenkins onto the Kubernetes cluster..."

helm upgrade --install jenkins --namespace jenkins stable/jenkins -f "${BASEDIR}"/files/jenkins-values.yaml > /dev/null

if [[ $? -eq 0 ]]; then
  echo -e "\033[32mJenkins has been successfully installed!\033[39m"
else
  echo -e "\033[31mThere was a problem installing Jenkins.\033[39m"
  exit 1
fi

echo "Please wait while the Jenkins pod comes online. This may take a few minutes..."
until [[ $(kubectl get pods -n jenkins 2>/dev/null | grep jenkins | awk -F " " '{print $2}' | awk -F "/" '{print $1}') -ge "1" ]]; do
  echo -n "."
  sleep 1
done;
echo # For newline.

echo -e "\033[32mJenkins is up and running!\033[39m"
echo "Jenkins can be accessed via https://${JENKINS_FQDN}"
JENKINS_PASSWORD=$(printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo)
echo -e "\033[33mYour default Jenkins password is\033[39m: ${JENKINS_PASSWORD}"
echo