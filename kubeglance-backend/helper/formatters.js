export const formatPods = (pods) => {
  return pods.map(pod => {

    const totalContainers = pod.spec.containers.length;
    const readyContainers = pod.status.containerStatuses ? pod.status.containerStatuses.filter(cs => cs.ready).length : 0;

    return {
      name: pod.metadata.name,
      namespace: pod.metadata.namespace,
      status: pod.status.phase,
      podIP: pod.status.podIP,
      hostIP: pod.status.hostIP,
      creationTimestamp: pod.metadata.creationTimestamp,
      node: pod.spec.nodeName,
      ready: readyContainers,
      total: totalContainers,
      containers: pod.spec.containers.map(container => ({
        name: container.name,
        image: container.image,
        ports: container.ports
          ? container.ports.map(port => ({
              containerPort: port.containerPort,
              protocol: port.protocol
            }))
          : []
      }))
    };
  });
};

export const formatDeployments = (deployments) => {
  return deployments.map(deployment => ({
    name: deployment.metadata.name,
    namespace: deployment.metadata.namespace,
    replicas: {
      desired: deployment.spec.replicas,
      available: deployment.status.availableReplicas || 0,
      ready: deployment.status.readyReplicas || 0
    },
    creationTimestamp: deployment.metadata.creationTimestamp,
    labels: deployment.metadata.labels
  }));
};

export const formatNamespaces = (namespaces) => {
  return namespaces.map(namespace => ({
    name: namespace.metadata.name,
    creationTimestamp: namespace.metadata.creationTimestamp,
    status: namespace.status.phase || 'Unknown',
  }));
};

export const formatServices = (services) => {
  return services.map(service => ({
    name: service.metadata.name,
    namespace: service.metadata.namespace,
    type: service.spec.type,
    clusterIP: service.spec.clusterIP,
    externalIPs: service.status?.loadBalancer?.ingress?.map(ing => ing.ip || ing.hostname) || [],
    ports: service.spec.ports ? service.spec.ports.map(port => ({
      port: port.port,
      targetPort: port.targetPort,
      nodePort: port.nodePort,
      protocol: port.protocol,
      name: port.name,
    })) : [],
    selector: service.spec.selector || {},
    creationTimestamp: service.metadata.creationTimestamp,
    labels: service.metadata.labels
  }));
};

export const formatEvents = (events) => {
  return events.map(event => ({
    name: event.metadata.name,
    namespace: event.metadata.namespace,
    reason: event.reason,
    message: event.message,
    involvedObject: {
      kind: event.involvedObject.kind,
      name: event.involvedObject.name
    },
    count: event.count || 1,
    timestamp: event.lastTimestamp || event.eventTime || event.metadata.creationTimestamp,
    type: event.type // Normal or Warning
  }));
};

export const formatSecrets = (secrets) => {
  
  return secrets.map(secret => ({
    name: secret.metadata.name,
    namespace: secret.metadata.namespace,
    type: secret.type,
    creationTimestamp: secret.metadata.creationTimestamp,
    dataKeys: Object.keys(secret.data || {}),
    annotations: secret.metadata.annotations || {},
    labels: secret.metadata.labels || {}
  }));
};

export const formatNodeMetrics = (nodeMetricsArray) => {
  return nodeMetricsArray.map((nodeMetric) => ({
    nodeName: nodeMetric.Node.metadata.name,
    cpu: {
      capacity: nodeMetric.CPU.Capacity,
      requestTotal: nodeMetric.CPU.RequestTotal,
      limitTotal: nodeMetric.CPU.LimitTotal,
    },
    memory: {
      capacity: Number(nodeMetric.Memory.Capacity),
      requestTotal: Number(nodeMetric.Memory.RequestTotal),
      limitTotal: Number(nodeMetric.Memory.LimitTotal),
    },
  }));
};


export const formatConfigMaps = (configMaps) => {
  
  return configMaps.map(configMap => ({
    name: configMap.metadata.name,
    namespace: configMap.metadata.namespace,
    creationTimestamp: configMap.metadata.creationTimestamp,
    dataKeys: Object.keys(configMap.data || {}),
    annotations: configMap.metadata.annotations || {},
    labels: configMap.metadata.labels || {}
  }));
};

export const calculateAge = (creationTimestamp) => {
  const created = new Date(creationTimestamp);
  const now = new Date();
  const diffMs = now - created;
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
  
  if (diffDays > 0) {
    return `${diffDays}d`;
  }
  
  const diffHrs = Math.floor(diffMs / (1000 * 60 * 60));
  if (diffHrs > 0) {
    return `${diffHrs}h`;
  }
  
  const diffMins = Math.floor(diffMs / (1000 * 60));
  return `${diffMins}m`;
};