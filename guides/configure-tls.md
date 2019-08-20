# Configuring TLS
Couchbase supports transport layer security (TLS) in order to encrypt communications on the wire and provide mutual authentication between peers. Couchbase clients (including the Couchbase Autonomous Operator) require the usage of TLS in order to communicate with the Couchbase cluster.

The basic requirements are:

* A certificate authority (CA) certificate which will be used by all actors to validate that peer certificates have been digitally signed by a trusted CA.

* A server certificate/key pair for all nodes in the Couchbase cluster. If you are using a hierarchy of intermediate CAs, these must be appended to the client certificate, ending in the intermediate CA that is signed by the top-level CA. Server certificates must have a subject alternative name (SAN) set so that a client can assert that the host name that it’s connecting to is the same as that in the certificate.

* Couchbase currently supports using wildcard entries only. For example,   **.cluster.domain.svc** where cluster is the name of the CouchbaseCluster resource, and domain is the namespace that the cluster is running in (typically **default**).

**Important:** TLS certificates are installed as part of the pod creation process, and cannot be enabled on an existing cluster.

## Creating Certificates
Creating X.509 certificates is beyond the scope of this documentation and is given only for illustrative purposes only.

### EasyRSA
EasyRSA by OpenVPN makes operating a public key infrastructure (PKI) relatively simple, and is the recommended method to get up and running quickly.

First clone the repository:

```
$ git clone http://github.com/OpenVPN/easy-rsa

Cloning into 'easy-rsa'...
warning: redirecting to https://github.com/OpenVPN/easy-rsa/
remote: Enumerating objects: 53, done.
remote: Counting objects: 100% (53/53), done.
remote: Compressing objects: 100% (37/37), done.
remote: Total 1313 (delta 17), reused 44 (delta 16), pack-reused 1260
Receiving objects: 100% (1313/1313), 5.53 MiB | 2.12 MiB/s, done.
Resolving deltas: 100% (594/594), done.
```

Initialize and create the CA certificate/key. You will be prompted for a private key password and the CA common name (CN), something like Couchbase CA is sufficient. The CA certificate will be available as pki/ca.crt.

```
$ cd easy-rsa/easyrsa3
```
```
$ ./easyrsa init-pki

init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: ~/pki
```

```
$ ./easyrsa build-ca

Using SSL: openssl LibreSSL 2.6.5

Enter New CA Key Passphrase:
Re-Enter New CA Key Passphrase:
Generating RSA private key, 2048 bit long modulus
....+++
..........................................................................................+++
e is 65537 (0x10001)
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:tls.emart.svc

CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
~/pki/ca.crt
```

Create a server wildcard certificate and key to be used on Couchbase Server pods. The Operator/clients will access the pods via Kubernetes services (**cb-eks-demo-0000.tls.emart.svc**, for example) so this needs to be in the SAN list in order for a client to verify the certificate belongs to the host that is being connected to.

To this end, we add in a **--subject-alt-name**, this can be specified multiple times in case your client uses a different method of addressing. The key/certificate pair can be found in **pki/private/couchbase-server.key** and **pki/issued/couchbase-server.crt** and used as **pkey.pem** and **chain.pem**, respectively, in the **serverSecret**.

You may be asked to enter passphrase that was used to generate the CA

```
$ ./easyrsa --subject-alt-name="DNS:*.tls.emart.svc" build-server-full couchbase-server nopass



Using SSL: openssl LibreSSL 2.6.5
Generating a 2048 bit RSA private key
..................................+++
............+++
writing new private key to '~/pki/easy-rsa-19774.jlNiVl/tmp.vnxTqG'
-----
Using configuration from ~/pki/easy-rsa-19774.jlNiVl/tmp.2QJ8Jq
Enter pass phrase for ~/pki/private/ca.key:
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'couchbase-server'
Certificate is to be certified until Aug  4 19:18:11 2022 GMT (1080 days)

Write out database with 1 new entries
Data Base Updated
```

Note: password-protected keys are not supported by Couchbase Server or the Operator.


### Private Key Formatting
Due to an [issue](https://issues.couchbase.com/browse/MB-24404) with Couchbase Server’s private key handling, server keys need to be PKCS#1 formatted. This can be achieved with the following commands:

```
$ cp pki/private/couchbase-server.key pkey.key
```
```
$ cp pki/issued/couchbase-server.crt chain.pem
```
```
$ openssl rsa -in pkey.key -out pkey.key.der -outform DER

writing RSA key
```
```
$ openssl rsa -in pkey.key.der -inform DER -out pkey.key -outform PEM

writing RSA key
```
