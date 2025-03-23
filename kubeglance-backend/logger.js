import winston from 'winston';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

export const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: 'kubeglance' },
  transports: [
    new winston.transports.Console(),
    
    new winston.transports.File({ 
      filename: path.join(logsDir, 'kubeglance.log'),
      maxsize: 5242880, // 5MB
      maxFiles: 5
    })
  ]
});

export default logger;