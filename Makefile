# Follow the instructions below:
# https://www.phildev.net/ssl/creating_ca.html

CA:=ca
CLIENT:=corp.logiocean.com

all: $(CLIENT)/csr.verify \
	$(CLIENT)/crt.verify

$(CA):
	mkdir -p $@

$(CA)/root.srl: $(CA)
	echo '00' > $@

$(CA)/root.key: $(CA)
	# Add `-des3` to enable passphrase.
	openssl genrsa -out $(CA)/root.key 4096

$(CA)/root.crt: $(CA)/root.key
	openssl req -x509 -new -nodes -sha256 -days 1024 \
        -subj "/C=CN/ST=Guangdong/O=LogiOcean/L=Shenzhen, Inc./CN=$(CLIENT)" \
        -key $< -out $@

$(CLIENT):
	mkdir -p $@

$(CLIENT)/key: $(CLIENT)
	openssl genrsa -out $(CLIENT)/key 4096

$(CLIENT)/csr: $(CLIENT)/key
	openssl req -new -key $< -out $@ \
		-subj "/C=CN/ST=Guangdong/L=Shenzhen/O=LogiOcean, Inc./OU=Corporate IT Team/CN=$(CLIENT)" \

$(CLIENT)/csr.verify: $(CLIENT)/csr
	openssl req -text -noout -in $< > $@

$(CLIENT)/crt: \
		$(CA)/root.key $(CA)/root.crt $(CLIENT)/csr $(CA)/root.srl
	openssl x509 -req -days 365 -sha256 \
        -CAcreateserial \
        -CAkey $(CA)/root.key \
        -CA $(CA)/root.crt \
        -in $(CLIENT)/csr \
        -out $(CLIENT)/crt

$(CLIENT)/crt.verify: $(CLIENT)/crt
	openssl x509 -text -noout -in $< > $@

clean:
	rm -rf $(CLIENT) $(CA)
