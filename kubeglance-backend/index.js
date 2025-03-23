import express from 'express';
import multer from 'multer';
import fs from 'fs-extra';
import path from 'path';
import cors from 'cors';
import { createNamespace, getEvents, getDeployments, getNamespaces, getPods, getServices, getSecrets, getConfigMaps, getCurrentContext, getClusterMetrics } from './services/k8sService.js';
import { logger } from './logger.js';

const app = express();

app.use(express.json())
app.use(cors())

const kubeconfigFilesPath = path.join('uploads', 'kubeconfigFiles.json');

const saveKubeconfigFiles = () => {
  fs.writeFileSync(kubeconfigFilesPath, JSON.stringify(kubeconfigFiles, null, 2), 'utf-8');
};

app.use((req, res, next) => {
  logger.info({
    method: req.method,
    url: req.url,
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });
  next();
});

app.get('/healthz', (req, res) => {
  res.status(200).json({ message: 'Healthy' });
});

app.get('/', (req, res) => {
  logger.info('Home route accessed');
  res.json({ message: 'API is running' });
});

app.get('/info', (req, res) => {
  logger.info('This is an info message');
  res.json({ message: 'Info message logged' });
});

app.get('/warn', (req, res) => {
  logger.warn('This is a warning message');
  res.json({ message: 'Warning message logged' });
});

app.get('/error', (req, res) => {
  logger.error('This is an error message');
  res.status(500).json({ error: 'Error message logged' });
});

app.get('/debug', (req, res) => {
  logger.debug('This is a debug message');
  res.json({ message: 'Debug message logged' });
});

const PORT = process.env.PORT || 3000;

const upload = multer({ dest: 'uploads/' });

let kubeconfigFiles = {};

app.get('/api/context', async (req, res) => {
  
  const userId = req.query.userId;

  if (!userId || !kubeconfigFiles[userId]) {
    return res.status(400).json({ error: 'Invalid or missing userId' });
  }

  try {
    const contextInfo = getCurrentContext(kubeconfigFiles[userId]);
    res.json(contextInfo);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/kubeconfig', upload.single('kubeconfig'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No kubeconfig file uploaded' });
  }

  const userId = Date.now().toString();
  const kubeconfigPath = path.join('uploads', `${userId}-kubeconfig`);

  logger.info("Kubeconfig Uploaded");

  fs.move(req.file.path, kubeconfigPath, { overwrite: true })
    .then(() => {
      kubeconfigFiles[userId] = kubeconfigPath;
      saveKubeconfigFiles();
      res.json({ userId, message: 'Kubeconfig uploaded successfully' });
    })
    .catch(err => res.status(500).json({ error: err.message }));
});

app.get('/api/kubeconfig', (req, res) => {
  const { userId } = req.query;
  const kubeconfigPath = path.join('uploads', `${userId}-kubeconfig`);

  fs.access(kubeconfigPath, fs.constants.F_OK, (err) => {
    if (err) {
      return res.status(404).json({ exists: false });
    }
    res.json({ exists: true });
  });
});

app.post('/api/namespaces', async (req, res) => {
  const userId = req.body.userId;
  const namespaceName = req.body.namespaceName;

  if (!userId || !kubeconfigFiles[userId]) {
    return res.status(400).json({ error: 'Invalid or missing userId' });
  }

  if (!namespaceName) {
    return res.status(400).json({ error: 'Namespace name is required' });
  }

  try {
    const namespace = await createNamespace(kubeconfigFiles[userId], namespaceName);
    res.json(namespace);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/namespaces', async (req, res) => {
  const userId = req.query.userId;
  const includePodCount = req.query.includePodCount || false;
  
  if (!userId || !kubeconfigFiles[userId]) {
    return res.status(400).json({ error: 'Invalid or missing userId' });
  }

  try {
    const namespaces = await getNamespaces(kubeconfigFiles[userId], includePodCount);
    res.json(namespaces);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/pods', async (req, res) => {
  const userId = req.query.userId;
  const namespace = req.query.namespace;

  if (!userId || !kubeconfigFiles[userId]) {
    return res.status(400).json({ error: 'Invalid or missing userId' });
  }

  try {
    const pods = await getPods(kubeconfigFiles[userId], namespace);
    res.json(pods);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/deployments', async (req, res) => {
  const userId = req.query.userId;
  const namespace = req.query.namespace;

  if (!userId || !kubeconfigFiles[userId]) {
    return res.status(400).json({ error: 'Invalid or missing userId' });
  }

  try {
    const pods = await getDeployments(kubeconfigFiles[userId], namespace);
    res.json(pods);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/services', async (req, res) => {
  const userId = req.query.userId;
  const namespace = req.query.namespace;

  if (!userId || !kubeconfigFiles[userId]) {
    return res.status(400).json({ error: 'Invalid or missing userId' });
  }

  try {
    const pods = await getServices(kubeconfigFiles[userId], namespace);
    res.json(pods);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/events', async (req, res) => {
  const userId = req.query.userId;
  const namespace = req.query.namespace;
  const limit = parseInt(req.query.limit);
  
  if (!userId || !kubeconfigFiles[userId]) {
    return res.status(400).json({ error: 'Invalid or missing userId' });
  }
  
  try {
    const events = await getEvents(kubeconfigFiles[userId], namespace, !isNaN(limit) ? limit : 10);
    res.json(events);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/metrics', async (req, res) => {
  const userId = req.query.userId;
  const namespace = req.query.namespace || null;
  
  if (!userId || !kubeconfigFiles[userId]) {
    return res.status(400).json({ error: 'Invalid or missing userId' });
  }
  
  try {
    const metrics = await getClusterMetrics(kubeconfigFiles[userId], namespace);
    res.json(metrics);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/secrets', async (req, res) => {
  const userId = req.query.userId;
  const namespace = req.query.namespace;

  if (!userId || !kubeconfigFiles[userId]) {
    return res.status(400).json({ error: 'Invalid or missing userId' });
  }

  try {
    const secrets = await getSecrets(kubeconfigFiles[userId], namespace);
    res.json(secrets);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/configmaps', async (req, res) => {
  const userId = req.query.userId;
  const namespace = req.query.namespace;

  if (!userId || !kubeconfigFiles[userId]) {
    return res.status(400).json({ error: 'Invalid or missing userId' });
  }

  try {
    const configMaps = await getConfigMaps(kubeconfigFiles[userId], namespace);
    res.json(configMaps);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/kubeconfig', async (req, res) => {
  const userId = req.query.userId;

  if (!userId || !kubeconfigFiles[userId]) {
    return res.status(400).json({ error: 'Invalid or missing userId' });
  }

  try {
    const kubeconfigPath = kubeconfigFiles[userId];

    await fs.remove(kubeconfigPath);
    delete kubeconfigFiles[userId];
    saveKubeconfigFiles();
    res.json({ message: 'Kubeconfig file deleted successfully' });
  } catch (err) {
    console.error('Error deleting kubeconfig:', err);
    res.status(500).json({ error: err.message });
  }
});


const cleanupOnExit = async () => {
  try {
    console.log('Server is shutting down... Cleaning up uploaded kubeconfig files.');
    kubeconfigFiles = {};

    const files = await fs.readdir('uploads');

    for (const file of files) {
      const filePath = path.join('uploads', file);
      await fs.remove(filePath);
      console.log(`Deleted file: ${filePath}`);
    }

    console.log('Cleanup complete');
  } catch (error) {
    console.error('Error during cleanup:', error);
  }
};

process.on('SIGINT', async () => {
  console.log('SIGINT received (Ctrl+C)');
  await cleanupOnExit();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('SIGTERM received');
  await cleanupOnExit();
  process.exit(0);
});

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

export default app;