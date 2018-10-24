# Initialize a private CA

This document is modified from [this
post](https://gist.github.com/fntlnz/cf14feb5a46b2eda428e000157447309).

NOTE:
> This document is not consistent with the `Makefile`.  It does not follow the
> best practices as described
> [here](https://www.phildev.net/ssl/creating_ca.html)

## Create the Root CA (only done once)

### Create the Root CA Key

requires: (empty)

yeilds:
- `ca.root.key`

Attention: this is the key used to sign the certificate requests, anyone holding
this can sign certificates on your behalf. So keep it in a safe place!

```bash openssl genrsa -des3 -out ca.root.key 4096 ```

If you want a non password protected key just remove the `-des3` option.

### Create and self sign the Root CA Certificate

requires:
- `ca.root.key`

yields:
- `ca.root.crt`

```bash openssl req -x509 -new -nodes -sha256 -days 1024 \ -subj
"/C=CN/ST=Guangdong/O=LogiOcean/L=Shenzhen, Inc./CN=corp.logiocean.com" \ -out
ca.root.crt \ -key ca.root.key ```


Here we used our root key to create the root certificate that needs to be
distributed in all the computers that have to trust us.

## Create the Client Certificates (done for each client)

This procedure needs to be followed for each client that needs a certificate
issued by our CA to gain trust from other clients that are trusting issuing CA.

### Create the Client Key

requires: (empty)

yields:
- `<client>.key`

NOTE:
> Using client = corp.logiocean.com for all examples hereafter.

```bash openssl genrsa -out corp.logiocean.com.key 4096 ```

Each client must generate its own client key.  Note that

### Create the Certificate Signing Request (CSR)

The certificate signing request is where you specify the details for the
certificate you want to generate.  This request will be processed by the owner
of the CA root key `ca.root.key`.  In this example, it would be you since you
generated `ca.root.key` earlier.

Important: Please mind that while creating the signign request is important to
specify the Common Name providing the IP address or domain name for the service,
otherwise the certificate cannot be verified.

Depending on your needs, there are two methods to generate a CSR.

#### Interactive Method

requies:
- `<client>.key`

yields:
- `<client>.csr`

If you generate the csr in this way, openssl will ask you questions about the
certificate to generate like the organization details and the Common Name (CN)
that is the web address you are creating the certificate for, e.g mydomain.com.

NOTE:
> Still using client = corp.logiocean.com, as described in an earlier section.

```bash openssl req -new \ -key corp.logiocean.com.key \ -out
corp.logiocean.com.csr ```

#### Batch Method

requies:
- `<client>.key`

yields:
- `<client>.csr`

This method generates the same output as the Interactive Method.

```bash openssl req -new -sha256 \ -subj
"/C=CN/ST=Guangdong/L=Shenzhen/O=LogiOcean, Inc./OU=Corporate IT
Team/CN=corp.logiocean.com" \ -key corp.logiocean.com.key \ -out
corp.logiocean.com.csr ```


#### Verify the csr's content requires:
- `<client>.key`

yields: (verification only)

```bash openssl req -in corp.logiocean.com.csr -noout -text ```

The above command should print to `stdout` something very similar to the
following: ```text Certificate Request: Data: Version: 0 (0x0) Subject: C=CN,
ST=Guangdong, O=LogiOcean, Inc., OU=Corporate IT Team, CN=corp.logiocean.com
Subject Public Key Info: Public Key Algorithm: rsaEncryption Public-Key: (4096
bit) Modulus: 00:e6:e9:8e:7e:c2:dd:c0:e2:76:a2:a5:05:3a:2b:
a5:9f:8a:28:a0:f9:3f:06:71:4f:15:55:4e:39:2f: (... omitted for brevity)
9c:87:23:26:aa:3f:0c:00:52:2b:98:48:1c:24:64: d3:b4:47 Exponent: 65537 (0x10001)
Attributes: a0:00 Signature Algorithm: sha256WithRSAEncryption
1f:08:94:80:12:e3:d1:86:49:8c:49:66:a1:40:c3:51:5a:28: (... omitted for brevity)
c6:13:06:61:c4:66:f9:88:ff:3a:3b:19:7c:29:99:25:9f:66: c0:b7:6c:ca:d6:a9:f5:c9
```

#### Generate the Client Certificate with the Root CA Key requires:
- `ca.root.key` `ca.root.crt` `<client>.csr`

yields:
- `<client>.crt` `ca.srl`

Generate a certificate for `corp.logiocean.com` valid for a year.  ```bash
openssl x509 -req -days 365 -sha256 \ -CAcreateserial \ -CAkey ca.root.key \ -CA
ca.root.crt \ -in corp.logiocean.com.csr \ -out corp.logiocean.com.crt ```

#### Verify the Generated Client Certificate requires:
- `<client>.crt`

yields: (verification only)

```bash openssl x509 -in corp.logiocean.com.crt -text -noout ```

This command should print to `stdout` something very similar to the following:
```text Certificate: Data: Version: 1 (0x0) Serial Number: 16530238180738844186
(0xe567340b5f89c61a) Signature Algorithm: sha256WithRSAEncryption Issuer: C=CN,
ST=Guangdong, O=LogiOcean, Inc., CN=corp.logiocean.com Validity Not Before: Oct
24 16:59:46 2018 GMT Not After : Oct 24 16:59:46 2019 GMT Subject: C=CN,
ST=Guangdong, O=LogiOcean, Inc., OU=Corporate IT Team, CN=corp.logiocean.com
Subject Public Key Info: Public Key Algorithm: rsaEncryption Public-Key: (4096
bit) Modulus: 00:e6:e9:8e:7e:c2:dd:c0:e2:76:a2:a5:05:3a:2b:
a5:9f:8a:28:a0:f9:3f:06:71:4f:15:55:4e:39:2f: (... omitted for brevity)
10:5f:e6:c5:c3:d8:cb:97:a4:3b:5f:c4:d4:75:f9:
9c:87:23:26:aa:3f:0c:00:52:2b:98:48:1c:24:64: d3:b4:47 Exponent: 65537 (0x10001)
Signature Algorithm: sha256WithRSAEncryption
46:61:43:b3:4a:eb:82:c4:15:00:8b:12:47:63:40:2d:a3:8c:
ff:eb:70:17:b2:43:76:fa:43:57:73:94:5c:2e:4e:df:9b:53: (... omitted for brevity)
1b:7c:87:1d:1b:bf:30:87:39:16:1d:83:21:4d:91:8e:9d:8f: d7:cc:9b:96:0d:5a:75:c6
```
