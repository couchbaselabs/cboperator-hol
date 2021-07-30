#! /bin/bash
set -x
set -eo pipefail
unset EASYRSA_SSL_CONF

root_ca_password=$(openssl rand -base64 12)
CLUSTER_NAME=$1
DOMAIN=cbdbdemo.com
NAMESPACE=cb

cert_temp_dir=$(mktemp -d)
pushd ${cert_temp_dir}


install_requirements () {
    wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz
    tar xvf EasyRSA-3.0.8.tgz
    cd EasyRSA-3.0.8
}

make_pki_ca () {
    ./easyrsa init-pki
    expect -f - <<- EOF
        spawn ./easyrsa build-ca
        expect "Enter New CA Key Passphrase:"
        send -- "${root_ca_password}\r"
        expect "Re-Enter New CA Key Passphrase:"
        send -- "${root_ca_password}\r"
        expect "Common Name"
        send -- "Couchbase CA\r"
        expect eof
EOF
# delete secret if existed
kubectl get secret ${CLUSTER_NAME}-ca-password && kubectl delete secret ${CLUSTER_NAME}-ca-password
kubectl create secret generic ${CLUSTER_NAME}-ca-password --from-literal=password=\'${root_ca_password}\'
kubectl label secret ${CLUSTER_NAME}-ca-password cluster=${CLUSTER_NAME} app=couchbase-tls
}

# FIXME make it generic
make_cb_server_cert () {
    # generate
    # see https://docs.couchbase.com/operator/current/tutorial-tls.html#creating-a-couchbase-cluster-server-certificate
    expect -f - <<- EOF
        spawn ./easyrsa --subject-alt-name='DNS:*.${CLUSTER_NAME},DNS:*.${CLUSTER_NAME}.${NAMESPACE},DNS:*.${CLUSTER_NAME}.${NAMESPACE}.svc,DNS:*.${CLUSTER_NAME}.${NAMESPACE}.svc.cluster.local,DNS:${CLUSTER_NAME}-srv,DNS:${CLUSTER_NAME}-srv.${NAMESPACE},DNS:${CLUSTER_NAME}-srv.${NAMESPACE}.svc,DNS:*.${CLUSTER_NAME}-srv.${NAMESPACE}.svc.cluster.local,DNS:*.${CLUSTER_NAME}.${DOMAIN},DNS:localhost,DNS:host.${DOMAIN}' build-server-full couchbase-server nopass
        expect "Enter pass phrase"
        send -- "${root_ca_password}\r"
        expect eof
EOF
    openssl rsa -in pki/private/couchbase-server.key -out pkey.key.der -outform DER
    openssl rsa -in pkey.key.der -inform DER -out pkey.key -outform PEM
    cp pki/issued/couchbase-server.crt ./chain.pem
    cp pki/ca.crt ca.crt
    cp pkey.key pkey.pem

    # inject into cluster as secret
    # delete secret if existed
    kubectl get secret ${CLUSTER_NAME}-server-tls -n $NAMESPACE && kubectl delete secret ${CLUSTER_NAME}-server-tls -n $NAMESPACE
    kubectl create secret generic ${CLUSTER_NAME}-server-tls --from-file ./pkey.key --from-file ./chain.pem --from-file ./pkey.pem -n $NAMESPACE
    # why do we label secrets and never use that label ?
    #kubectl label secret/${CLUSTER_NAME}-server-tls cluster=${CLUSTER_NAME} app=couchbase-tls -n $NAMESPACE
}

# the client cert is for the cbop
make_cbop_cert () {
    # see https://docs.couchbase.com/operator/current/tutorial-tls.html#creating-a-client-certificate
    expect -f - <<- EOF
        spawn ./easyrsa build-client-full Administrator nopass
        expect "Enter pass phrase"
        send -- "${root_ca_password}\r"
        expect eof
EOF
    cp pki/private/Administrator.key ./couchbase-operator.key
    cp pki/issued/Administrator.crt ./couchbase-operator.crt
    # delete secret if existed
    kubectl get secret ${CLUSTER_NAME}-operator-tls -n $NAMESPACE && kubectl delete secret ${CLUSTER_NAME}-operator-tls -n $NAMESPACE
    kubectl create secret generic ${CLUSTER_NAME}-operator-tls --from-file ./ca.crt --from-file ./couchbase-operator.key --from-file ./couchbase-operator.crt -n $NAMESPACE
    # why do we label secrets and never use that label ?
    #kubectl label secret/${CLUSTER_NAME}-operator-tls cluster=${CLUSTER_NAME} app=couchbase-tls -n $NAMESPACE
}


cleanup () {
    popd
    rm -rf ${cert_temp_dir}
}

## Script
#check_certs 2>/dev/null
install_requirements
make_pki_ca
make_cb_server_cert
make_cbop_cert
#make_cbop_dac_cert
#submit_cb_server_certs || true
cleanup
