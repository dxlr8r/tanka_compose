local index_php=importstr 'index.php';
{  
  name: 'example-com',
  ConfigMap+: {
    'index.php': index_php,
  },
  Ingress+: {
    mixin: {
      metadata+: {
        annotations: {
          'haproxy-ingress.github.io/cert-signer': 'acme',
          'kubernetes.io/tls-acme': 'true' }}}
  },
  Deployment+: {
    replicas: 2,
    containers: {
      apache: {
        image: 'php:apache',
        mountPathConfigMap: '/var/www/html',
        ports: {
          ingress: 80,
          liveness: 80
        },
        ingress: {
          name: 'example.com',
          alt: ['www.example.com'],
          tls_secret: 'example-com',
        },
        mixin: {
          env+:[{name: "ATTACH", value: "Welcome to example.com"}]}}}}}
