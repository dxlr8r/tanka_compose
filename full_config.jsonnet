{
  // **NOTE** 
  // Someplaces we use `+:` instead of `:` as a field separator. Unless you know what you are doing, don't change them in your config.

  // Required: will be used as a name for the resources, and used as a base inside the resources as well
  name: 'tk-compose',
  // Optional: name of namespace to target, and create if not present. If not specified will use value of `name`.
  namespace: 'tk-compose',
  
  // optional: create a ConfigMap
  ConfigMap+: {
    // required: define minimum 1 key:value pair
    'myconfig.yaml': 'hello: world',
    'mydata.txt': 'tanka > helm'
  },
  // optional: create a Secret
  Secret+: {
    // required: define minimum 1 key:value pair
    'mytoken': 'supersecret'
  },
  // optional: create a PVC
  Volume+: {
    accessModes: ['ReadWriteOnce'], # optional
    size_request: '1Gi', # optional
    storageClassName: 'local-path' # optional
  },
  // optional: create an EmptyDir
  EmptyDir+: {
    size_limit: '10Mi' # optional
  },
  // optional: create an Ingress
  Ingress+: {
    mixin: {} # optional: apply object to resource
  },
  // optional: create Daemonset
  // Daemonset: {
    # same as Deployment, except Deployment's replicas field
  // },
  // Optional: create Deployment
  Deployment+: {
    replicas: 1, # optional
    securityContext: {}, # optional, recommened to use comment/use defaults
    containers: { # required
      busybox_echoserver: { # required: atleast one
        image: 'busybox:latest', # required
        // optional: pick ConfigMap to expose as volumeMounts and Env
        withConfigMap: ['myconfig.yaml'],
        // optional: pick Secrets to expose as volumeMounts and Env
        withSecret: ['mytoken'],
        // optional: mount ConfigMaps to this directory
        mountPathConfigMap: '/ConfigMap',
        // optional: subPath for mountPathConfigMap
        subPathConfigMap: 'config.yaml',
        // optional: mount Secrets to this directory
        mountPathSecret: '/Secret',
        // optional: subPath for mountPathSecret
        subPathSecret: 'token.yaml',
        // optional: mount claimed PhysicalVolume to this directory
        mountPathVolume: '/PersistentVolume',
        // optional: subPath for mountPathVolume
        subPathVolume: 'hello',
        // optional: defined container's ports
        ports: {
          ingress: '8080:8080', # recommended if Ingress and ingress is defined
          liveness: 8080 # optional, used as tcp livenessProbe 
        },
        // optional: define ingress for resource
        ingress: {
          name: 'example.com', # required
          alt: ['hello.example.com'], # optional: alternative subjects
          // optional: name of Secret containing certificates for https
          tls_secret: 'example-com',
          pathMixin: {} # optional: apply object to resource's path
        },
        # optional: apply object to resource
        mixin: {
          env+:[{name: "MY_ENV", value: "TRUE"}],
          command: ['/bin/sh'],
          args: ['-c', 'nc -ll -p 8080 -e /bin/cat']
        }
      }
    }
  }
}
