# Kubernetes Scaffolding Script

## What is this?

While experimenting with Kubernetes on DigitalOcean, I found myself spinning up clusters fairly often to try new things. I got very familiar with the process of doing this and decided to [write a guide](https://gist.github.com/DefrostedTuna/1cf0367b3b121d82a0591e177d6887b8) covering how to set up a barebones cluster, along with common tools that I personally use. This bash script project is an extension of that guide, automating the process of setting up a cluster on DigitalOcean and installing a subset of software to get fresh cluster up and running quickly.

## What are the requirements?

* MacOS Mojave (Untested on other Unix based systems, or other versions of MacOS)
* Homebrew
* Kubectl
* Helm
* Doctl

## What does it install and configure?

The script will first and foremost check for the proper dependencies. These dependencies include:

* Homebrew
* Kubectl
* Helm
* Doctl

If these dependencies are not found on the system, the script will attempt to install them for you.

**Note:** The Homebrew installation may take a considerable amount of time if the X Code Development Tools are not found on your system.

Once these dependencies are present the script will configure the following:

* Creating a Kubernetes cluster on DigitalOcean
* Copying a kubeconfig file to your local machine (If opted against creating a cluster)
* Initializing Helm/Tiller
* Installing an Nginx Ingress
* Installing Cert Manager
* Installing and configuring Jenkins
* Installing and configuring Harbor
* Installing Kubernetes Dashboard

**Note:** Setting up the Ingress *WILL* configure a DigitalOcean Load Balancer. This is a service that DigitalOcean charges for, so keep that in mind.

## How do I use this script?

Clone the repository onto your local machine.

```
https://github.com/DefrostedTuna/kubernetes-scaffolding.git && cd kubernetes-scaffolding
```

Make the script executable.

```
chmod +x init-cluster.sh && chmod -R +x scripts
```

Run the script.

```
./init-cluster.sh
```

The script will guide you through the setup process, prompting for input when necessary. Follow the instructions in the script and you'll be good to go!