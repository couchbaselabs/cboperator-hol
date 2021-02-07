#!/bin/bash

# Details steps to generate certs using easyrsa is described in the link below:
# https://docs.couchbase.com/operator/current/tutorial-tls.html#easyrsa

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#  Function _usage
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
_usage()
{
   echo -e "Usage: ./createTLS.sh [options]"
   echo -e "This script will take a Couchbase cluster-name, namespace (where it is deployed) and subdomain to generate TLS certificates with required DNS subject alternate names (SAN). Make sure easyrsa is in the path to run this script."
   echo -e "Options:"
   echo -e "	-c  <s>  Couchbase Cluster name used in the couchbase-cluster.yaml file (default: cb-example)"
   echo -e "	-n  <s>  Namespace where cluster is deployed (default: default)"
   echo -e "	-d  <s>  Subdomain to be used as a wild card in the DNS SAN (default: dc.pge.com)"
   exit 5 # Exit script after printing help
}


# set the defaults, these can all be overriden as environment variables or passed via the cli
CLUSTER=${CLUSTER:='cb-example'}
NAMESPACE=${NAMESPACE:='default'}
SUBDOMAIN=${SUBDOMAIN:='*.dc.pge.com'}

#default directory where easyrsa updates the certs
PKI_DIR="/usr/local/etc/pki"

# for arg in "$@"
while getopts c:n:d:h flag
do
  # case "$arg" in
  case "${flag}" in
    c) CLUSTER=${OPTARG};;
    n) NAMESPACE=${OPTARG};;
    d) SUBDOMAIN=${OPTARG};;
    h) _usage
  esac
done

# echo -e "cluster: $CLUSTER, namespace: $NAMESPACE, domain: $SUBDOMAIN \n"
SAN='DNS:*.cluster-name,DNS:*.cluster-name.namespace,DNS:*.cluster-name.namespace.svc,DNS:*.cluster-name.namespace.svc.cluster.local,DNS:cluster-name-srv,DNS:cluster-name-srv.namespace,DNS:cluster-name-srv.namespace.svc,DNS:*.cluster-name-srv.namespace.svc.cluster.local,DNS:localhost,DNS:*.subdomain'
#replace cluster-name, namespace and Subdomain
SAN="${SAN//cluster-name/$CLUSTER}"
SAN="${SAN//namespace/$NAMESPACE}"
SAN="${SAN//subdomain/$SUBDOMAIN}"



initCert ()
{
  easyrsa init-pki
  easyrsa build-ca nopass
  easyrsa --subject-alt-name=$SAN build-server-full couchbase-server nopass

  echo -e "subject-alt-name=$SAN \n"

  echo -e "Creating directory: $/tmp/SUBDOMAIN ..."
  # rm -rf "/tmp/$DOMAIN"
  mkdir -p "/tmp/$SUBDOMAIN"
  cp "$PKI_DIR/private/couchbase-server.key" "/tmp/$SUBDOMAIN/pkey.key"
  cp "$PKI_DIR/issued/couchbase-server.crt" "/tmp/$SUBDOMAIN/chain.pem"
  cp "$PKI_DIR/ca.crt" "/tmp/$SUBDOMAIN"

  cd "/tmp/$SUBDOMAIN"
  # Due to an issue with Couchbase Server’s private key handling, server keys
  # need to be [PKCS#1](https://issues.couchbase.com/browse/MB-24404) formatted.
  openssl rsa -in pkey.key -out pkey.key.der -outform DER
  openssl rsa -in pkey.key.der -inform DER -out pkey.key
}

# Create TLS certificates
initCert
