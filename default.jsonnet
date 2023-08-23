{  
  name: 'common',
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