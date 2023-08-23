# SPDX-FileCopyrightText: 2023 Simen Strange <https://github.com/dxlr8r/kube.acme.sh>
# SPDX-License-Identifier: MIT

function(lib, mod, config)
local obj = lib.dx.obj;
local test = lib.dx.test;
local ternary = test.ternary;
local str = lib.dx.string;
local controller = 
       if std.objectHas(config, 'Deployment') then 
        std.get(config, 'Deployment') + {kind: 'Deployment'}
  else if std.objectHas(config, 'Daemonset')  then 
        std.get(config, 'Daemonset')  + {kind: 'Daemonset'}
  else error '.Deployment or .Daemonset need to be defined';

local manifest =
{
  Namespace: {
    apiVersion: 'v1',
    kind: 'Namespace',
    metadata: {
      name: config.namespace
    }
  },
  ConfigMap: test.exists(config, 'ConfigMap', {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      name: config.name
    },
    data: config.ConfigMap
  }),

  Secret: test.exists(config, 'Secret', {
    apiVersion: 'v1',
    kind: 'Secret',
    metadata: {
      name: config.name
    },
    data: obj.forEach(function(f,v) {
      [f]: std.base64(v)
    }, config.Secret)
  }),

  Ingress: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      // annotations: {
      //   'haproxy-ingress.github.io/cert-signer': 'acme',
      //   'kubernetes.io/tls-acme': 'true',
      // },
      name: config.name,
    },
    spec: {
      // ingressClassName: 'haproxy',
      rules: std.flattenArrays(
      [
        [
          {
            host: domain,
            http: {
              paths: [
                {
                  backend: {
                    service: {
                      name: config.name,
                      port: {
                        number: lib.svcPort(container.value.ports.ingress)
                      }}},
                  path: '/',
                  pathType: 'Prefix'
                }
                +
                std.get(container.value.ingress, 'pathMixin', {})
            ]}
          } for domain in 
              std.get(container.value.ingress, 'alt', []) + 
                [container.value.ingress.name]
      ] for container in std.objectKeysValues(controller.containers)
        if std.objectHas(container.value, 'ingress')
        if std.objectHas(container.value, 'ports') && 
           std.objectHas(container.value.ports, 'ingress')
        ]),
      tls: [
        {
          hosts: std.get(container.value.ingress, 'alt', []) + 
                        [container.value.ingress.name],
          secretName: container.value.ingress.tls_secret,
        } for container in std.objectKeysValues(controller.containers)
          if std.objectHas(container.value, 'ingress') &&
             std.objectHas(container.value.ingress, 'tls_secret')]
    }
  } 
  +
  std.get(std.get(config, 'Ingress', {}), 'mixin', {}),

  PersistentVolumeClaim: test.exists(config, 'Volume', {
    apiVersion: 'v1',
    kind: 'PersistentVolumeClaim',
    metadata: {
      name: config.name
    },
    spec: {
      accessModes: config.Volume.accessModes,
      resources: {
        requests: {
          storage: config.Volume.size_request,
        }
      }
    } 
    + 
    test.exists(config.Volume, 'storageClassName', 
      { storageClassName: config.Volume.storageClassName })
  }),

  Service: {
    kind: 'Service',
    apiVersion: 'v1',
    metadata: {
      name: config.name
    },
    spec: {
      type: 'ClusterIP',
      ports: std.flattenArrays([
        [
          {
            name: '%s-%s' % [container, port.key],
            protocol: 'TCP',
            port: lib.svcPort(port.value),
            targetPort: lib.targetPort(port.value),
          } for port in std.uniq(std.objectKeysValues(
              std.get(
                std.get(controller.containers, container, {}),
                'ports', {})), function(x) x.value)
        ] for container in std.objectFields(controller.containers)]),
      selector: config.labels
    }
  },
  [controller.kind]: {
    kind: controller.kind,
    apiVersion: 'apps/v1',
    metadata: {
      name: config.name
    },
    spec: {
      selector+: { matchLabels: config.labels },
      template: {
        metadata: {
          annotations: obj.forEach(function(f,v) {
            ['%s-md5sum' % f]: std.md5(v)
          }, std.get(config, 'ConfigMap', {}))
        } + { labels: config.labels },
        spec: {
          securityContext: controller.securityContext,
          volumes: 
          [
            { 
              name: str.rfc1123('configmap-%s-%s' % [config.name, vol.key]),
              configMap: {
                name: config.name,
                items: [{
                  key: vol.key,
                  path: vol.key
                }]
              }
            } for vol in std.objectKeysValues(std.get(config, 'ConfigMap', {}))  
          ]
          +
          [
            { 
              name: str.rfc1123('secret-%s-%s' % [config.name, vol.key]),
              secret: {
                secretName: config.name,
                items: [{
                  key: vol.key,
                  path: vol.key
                }]
              }
            } for vol in std.objectKeysValues(std.get(config, 'Secret', {}))
          ]
          +
          [
            test.exists(config, 'Volume', {
              name: 'pvc-%s' % config.name,
              persistentVolumeClaim: {
                claimName: config.name
              }})
          ]
          +
          [
            test.exists(config, 'EmptyDir', {
              name: 'empty-dir-%s' % config.name,
              emptyDir: {
                sizeLimit: config.EmptyDir.size_limit,
              }})
          ],
          containers: [
            {
              name: container.key,
              image: container.value.image,
              imagePullPolicy: 'Always',
              ports:
              [{
                  name: '%s-%s' % [container.key, port.key],
                  containerPort: lib.targetPort(port.value)
                }
                for port in std.uniq(std.objectKeysValues(
                std.get(container.value, 'ports', {})), function(x) x.value)],
              env:
              [ 
                { name: str.posixEnv(env.key), 
                  valueFrom: { configMapKeyRef: { 
                    name: config.name,
                    key: env.key }}
                } for env in 
                    std.objectKeysValues(std.get(config, 'ConfigMap', {}))
                  if (std.objectHas(container.value, 'withConfigMap') 
                      && std.member(container.value.withConfigMap, env.key)) 
                      || ! std.objectHas(container.value, 'withConfigMap')
              ]
              +
              [ 
                { name: str.posixEnv(env.key), 
                  valueFrom: { secretKeyRef: { 
                    name: config.name,
                    key: env.key }}
                } for env in 
                    std.objectKeysValues(std.get(config, 'Secret', {}))
                  if (std.objectHas(container.value, 'withSecret') 
                      && std.member(container.value.withConfigMap, env.key)) 
                      || ! std.objectHas(container.value, 'withSecret')
              ],
              volumeMounts: 
              [
                {
                  name: str.rfc1123('configmap-%s-%s' % [config.name, vol.key]),
                  mountPath: 
                    '%s/%s' % [container.value.mountPathConfigMap, vol.key],
                  subPath: vol.key,
                } for vol in std.objectKeysValues(
                    std.get(config, 'ConfigMap', {}))
                  if std.objectHas(container.value, 'mountPathConfigMap')
                  if (std.objectHas(container.value, 'withConfigMap') 
                      && std.member(container.value.withConfigMap, vol.key)) 
                      || ! std.objectHas(container.value, 'withConfigMap')
              ]
              +
              [
                {
                  name: 'secret-%s-%s' % [config.name, vol.key],
                  mountPath: 
                    '%s/%s' % [container.value.mountPathSecret, vol.key],
                  subPath: vol.key,
                } for vol in std.objectKeysValues(
                    std.get(config, 'Secret', {}))
                  if std.objectHas(container.value, 'mountPathSecret')
                  if (std.objectHas(container.value, 'withSecret') 
                      && std.member(container.value.withConfigMap, vol.key)) 
                      || ! std.objectHas(container.value, 'withSecret')
              ]
              +
              if std.objectHas(config, 'Volume') &&
                 std.objectHas(container.value, 'mountPathVolume') then [
                {
                  name: 'pvc-%s' % config.name,
                  mountPath: container.value.mountPathVolume,
                }
                +
                test.exists(container.value, 'subPathVolume',
                  { subPath: container.value.subPathVolume })]
              else []
              +
              if std.objectHas(config, 'EmptyDir') &&
                 std.objectHas(container.value, 'mountPathEmptyDir') then [
                {
                  name: 'empty-dir-%s' % config.name,
                  mountPath: container.value.mountPathEmptyDir,
                }]
              else []
            }
            +
            test.exists(std.get(container.value, 'ports', {}), 'liveness', 
              { livenessProbe: { tcpSocket: { 
                port: lib.targetPort(container.value.ports.liveness) }}})
            + 
            std.get(container.value, 'mixin', {})
            for container in std.objectKeysValues(
              std.get(controller, 'containers', {}))
          ]
        }
      }
    } 
    +
    ternary(
      controller.kind == 'Deployment',
      { replicas: controller.replicas },
      {})
  }
};

obj.forEach(function(f,v) 
if std.objectHas(v, 'apiVersion') then { 
  [f]: v + { metadata+: { labels: config.labels } }
}, manifest) + { config:: config, lib:: lib } // apply labels to all resources
