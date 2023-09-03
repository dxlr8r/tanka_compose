# Tanka Compose

`Tanka Compose` is a project to provision Kubernetes applications in a fast an easy way. `Tanka Compose` only require you do give it some input, like the container image you intend to use, etc. And it will take care of the rest.

The projects goal is to fit simpler deployments, to host a webpage in Apache, streaming services like Navidrome, hosting a WebDav server, etc.

Based on the simple configuration `Tanka Compose` will, on demand, provision: Deployment/Daemonset, Service, Ingress, PhysicalVolume, ConfigMap and a Secret, all tied together.

While `Tanka Compose` will not fit all deployments, it uses `Tanka`, meaning you with some additional knowledge can tweak the chart to do things the maintainer never planed. Using patches and mixins you can alter a lot to tailor it further to your needs. See our [example.com](example/example.com) as an example of this.

## Installing

First you need to install [tanka](https://tanka.dev/install), for this project `Jsonnet Bundler` is not used.

Then set a name for your project:

```sh
tkc_proj=my_project
```

Then create your project and clone this repository:

```sh
mkdir -p "$tkc_proj"
cd "$tkc_proj"
git clone https://github.com/dxlr8r/tanka_compose.git chart
cp chart/full_config.jsonnet config.jsonnet
```

Then setup the config file, using `full_config.jsonnet` as a template and reference.

Then provision the chart to your current kubectl context using `tk` (tanka):

```sh
tk apply chart --tla-str context=$(kubectl config current-context) --tla-code config="$(cat config.jsonnet)"
```

### full_config.jsonnet

Unmodified using `full_config.jsonnet` will yield a working example as well, except for the Ingress as you probably do not own `example.com`.

After deploying it, you can test the `nc` echo server it deployed:

```
kubectl -n tk-compose port-forward svc/tk-compose 8080:8080
echo hallo world | nc localhost 8080
```
