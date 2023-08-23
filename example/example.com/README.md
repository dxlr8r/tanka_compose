# example.com

This example will install the web-page example.com. Unless you own `example.com` you need to edit the `config.jsonnet` to match your domain. 

This chart comes with annotations to automatically setup the Ingress TLS with `Let's Encrypt` certificates. The annotations are custom to [jcmoraisjr/haproxy-ingress](https://github.com/jcmoraisjr/haproxy-ingress).

## Install

```sh
tkc_proj=example.com
mkdir -p "$tkc_proj"
cd "$tkc_proj"
git clone https://github.com/dxlr8r/tanka_compose.git chart
cp chart/example/example.com/{config.jsonnet,index.php} .
```

## Test

Test using curl:

```
curl -k https://example.com
```

Replace `example.com` with your domain. `-k` is required if you don't have a valid certificate (using a different ingress-controller than `jcmoraisjr/haproxy-ingress`, didn't tweak the annotations, etc.).
