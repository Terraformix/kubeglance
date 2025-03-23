import * as k8s from '@kubernetes/client-node';
import { formatDeployments, formatEvents, formatNamespaces, formatPods, formatServices, formatSecrets, formatConfigMaps } from '../helper/formatters.js';

const loadKubeConfig = (kubeconfigPath) => {
  const kc = new k8s.KubeConfig();
  kc.loadFromFile(kubeconfigPath);
  return kc;
};

export const getNamespaces = async (kubeconfigPath, includePodCount = false) => {
  const kc = loadKubeConfig(kubeconfigPath);
  const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
 
  try {
    const namespaceResponse = await k8sApi.listNamespace();
    const namespaces = formatNamespaces(namespaceResponse.items);
    
    if (!includePodCount) {
      return namespaces;
    }
    
    const podsResponse = await k8sApi.listPodForAllNamespaces();
    const allPods = podsResponse.items;
    
    const podCountMap = {};
    
    namespaces.forEach(ns => {
      podCountMap[ns.name] = 0;
    });
    
    allPods.forEach(pod => {
      const namespace = pod.metadata.namespace;
      if (podCountMap[namespace] !== undefined) {
        podCountMap[namespace]++;
      }
    });
    
    return namespaces.map(namespace => ({
      ...namespace,
      totalPods: podCountMap[namespace.name] || 0
    }));
    
  } catch (err) {
    console.error(`Error getting namespaces with pod counts:`, err);
    throw err;
  }
};

export const getCurrentContext = (kubeconfigPath) => {
    const kc = loadKubeConfig(kubeconfigPath);
    
    return {
      name: kc.getCurrentCluster().name,
      server: kc.getCurrentCluster().server
    };
  };
  

export const getPods = async (kubeconfigPath, namespace) => {
  const kc = loadKubeConfig(kubeconfigPath);
  const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
  
  try {

    let response;

    if (namespace) {
      response = await k8sApi.listNamespacedPod({ namespace });
    } else {
      response = await k8sApi.listPodForAllNamespaces();
    }

    return formatPods(response.items);
  } catch (err) {
    console.error(`Error listing pods in namespace ${namespace}:`, err);
    throw err;
  }
};

export const createNamespace = async (kubeconfigPath, namespaceName) => {
  try {
    const namespace = {
      apiVersion: 'v1',
      kind: 'Namespace',
      metadata: {
        name: namespaceName
      }
    };

    const kc = loadKubeConfig(kubeconfigPath);
    const k8sApi = kc.makeApiClient(k8s.CoreV1Api);


    const response = await k8sApi.createNamespace({
      body: namespace
    });
    return response.body;
  } catch (error) {
    console.error('Error creating namespace:', error);
    throw error;
  }
};

export const getDeployments = async (kubeconfigPath, namespace) => {
  const kc = loadKubeConfig(kubeconfigPath);
  const k8sApi = kc.makeApiClient(k8s.AppsV1Api);
  
  try {
    
    let response;

    if (namespace) {
      response = await k8sApi.listNamespacedDeployment({ namespace });
    } else {
      response = await k8sApi.listDeploymentForAllNamespaces();
    }

    return formatDeployments(response.items);
  } catch (err) {
    console.error(`Error listing deployments in namespace ${namespace}:`, err);
    throw err;
  }
};


export const getServices = async (kubeconfigPath, namespace) => {
  const kc = loadKubeConfig(kubeconfigPath);
  const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
  
  try {

    let response;

    if (namespace) {
      response = await k8sApi.listNamespacedService({ namespace });
    } else {
      response = await k8sApi.listServiceForAllNamespaces();
    }

    return formatServices(response.items);
  } catch (err) {
    console.error(`Error listing services in namespace ${namespace}:`, err);
    throw err;
  }
};

export const getEvents = async (kubeconfigPath, namespace = "", limit = 10) => {
  const kc = loadKubeConfig(kubeconfigPath);
  const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
  
  try {

    let response;

    if (namespace) {
      response = await k8sApi.listNamespacedEvent({ namespace });
    } else {
      response = await k8sApi.listEventForAllNamespaces();
    }

    // Sort events by timestamp (newest first)
    const sortedEvents = response.items.sort((a, b) => {
      const timeA = new Date(a.lastTimestamp || a.eventTime || a.metadata.creationTimestamp);
      const timeB = new Date(b.lastTimestamp || b.eventTime || b.metadata.creationTimestamp);
      return timeB - timeA;
    });
    
    return formatEvents(sortedEvents.slice(0, limit));
  } catch (err) {
    console.error('Error fetching events:', err);
    throw err;
  }
};

export const getClusterMetrics = async (kubeconfigPath, namespace = null) => {
    const kc = loadKubeConfig(kubeconfigPath);
    const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
    
    try {
      const nodeMetrics = await k8s.topNodes(k8sApi);

      return {
        nodes: formatNodeMetrics(nodeMetrics),
        //pods: podMetrics
      };
    } catch (err) {
      console.error('Error fetching metrics:', err);
      throw err;
    }
  };
  
  const formatNodeMetrics = (nodeMetricsArray) => {
    return {
      nodes: nodeMetricsArray.map((nodeMetric) => {
        const nodeName = nodeMetric.Node.metadata.name;
        const cpuCapacity = nodeMetric.CPU.Capacity;
        const cpuUsage = nodeMetric.CPU.Usage || nodeMetric.CPU.RequestTotal;
        const memoryCapacityBytes = Number(nodeMetric.Memory.Capacity);
        const memoryUsageBytes = Number(nodeMetric.Memory.Usage) || Number(nodeMetric.Memory.RequestTotal);
  
        const cpuMillicores = Math.round(cpuUsage * 1000); // Convert to millicores
        const cpuUsagePercentage = ((cpuUsage / cpuCapacity) * 100).toFixed(0) + "%";
  
        const memoryMi = Math.round(memoryUsageBytes / 1048576); // Convert bytes to MiB
        const memoryCapacityMi = Math.round(memoryCapacityBytes / 1048576);
        const memoryUsagePercentage = ((memoryUsageBytes / memoryCapacityBytes) * 100).toFixed(0) + "%";
  
        return {
          name: nodeName,
          cpu: `${cpuMillicores}m`,
          cpuPercentage: cpuUsagePercentage,
          memory: `${memoryMi}Mi`,
          memoryPercentage: memoryUsagePercentage,
        };
      }),
    };
  };
  
  
  const formatPodMetrics = (pods) => {
    return pods.map(pod => ({
      name: pod.name,
      namespace: pod.namespace,
      containers: pod.containers.map(container => ({
        name: container.name,
        cpu: container.cpu,
        memory: container.memory
      })),
      cpu: pod.cpu,
      memory: pod.memory
    }));
  };

export const getSecrets = async (kubeconfigPath, namespace = '') => {
  const kc = loadKubeConfig(kubeconfigPath);
  const k8sApi = kc.makeApiClient(k8s.CoreV1Api);

  try {
    let response;

    if (namespace) {
      response = await k8sApi.listNamespacedSecret({namespace});
    } else {
      response = await k8sApi.listSecretForAllNamespaces();
    }

    return formatSecrets(response.items);
  } catch (err) {
    console.error('Error listing secrets:', err);
    throw err;
  }
};

export const getConfigMaps = async (kubeconfigPath, namespace = '') => {
  const kc = loadKubeConfig(kubeconfigPath);
  const k8sApi = kc.makeApiClient(k8s.CoreV1Api);

  try {
    let response;

    if (namespace) {
      response = await k8sApi.listNamespacedConfigMap({namespace});
    } else {
      response = await k8sApi.listConfigMapForAllNamespaces();
    }

    return formatConfigMaps(response.items);
  } catch (err) {
    console.error('Error listing configmaps:', err);
    throw err;
  }
};