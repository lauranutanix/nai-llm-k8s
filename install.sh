#!/bin/bash

kf_version=1.7.0

helpFunction()
{
   echo ""
   echo "Usage: $0 -d <COMPANY_DOMAIN>"
   echo "\t-d provide company domain e.g. ntnx.com"
   exit 1 # Exit script after printing help
}

while getopts ":d:" opt;
do
   case "$opt" in
        d ) company_domain="$OPTARG" ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

if [ -z "$company_domain"  ] 
then
    echo "Company domain not provided"
    helpFunction
fi

# Download kubeflow manifests
wget https://github.com/kubeflow/manifests/archive/refs/tags/v"$kf_version".zip
unzip v"$kf_version".zip; mv manifests-"$kf_version" manifests

# Install kubeflow
while ! kustomize build install-kubeflow  | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 15; done

# Apply patches
kubectl patch cm config-domain -p "{\"data\": {\"$company_domain\": \"\"}}" -n knative-serving
kubectl patch service istio-ingressgateway -p '{"spec": {"type": "LoadBalancer"}}' -n istio-system

# Remove kubeflow manifests
rm v"$kf_version".zip
rm -rf manifests
