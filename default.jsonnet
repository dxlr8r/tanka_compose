# SPDX-FileCopyrightText: 2023 Simen Strange <https://github.com/dxlr8r/kube.acme.sh>
# SPDX-License-Identifier: MIT

{
  namespace: $.name,
  labels: { app: $.name },
  Deployment: {
    replicas: 1,
    securityContext: { 
      runAsNonRoot: true,
      runAsUser: 1000,
      runAsGroup: 1000,
      fsGroup: 2000 
    },
  },
  Volume: {
    accessModes: ['ReadWriteOnce'],
    size_request: '1Gi',
  },
  EmptyDir: {
    size_limit: '10Mi'
  }
}