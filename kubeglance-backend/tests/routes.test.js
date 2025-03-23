import { expect, jest } from '@jest/globals';
import request from 'supertest';

// Mock the logger
jest.mock('../logger.js', () => ({
  logger: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    debug: jest.fn()
  }
}));

jest.useFakeTimers();

describe('Basic Routes', () => {
  let app;
  let server;

  beforeAll(async () => {
    const appModule = await import('../index.js');
    app = appModule.default;

    // Start the server if it exports one
    if (app.listen) {
      server = app.listen(); // Start listening to a random port
    }
  });

  afterAll((done) => {
    if (server) {
      server.close(done); // Close the server to ensure Jest exits cleanly
    } else {
      done();
    }
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('GET / returns API running message', async () => {
    const response = await request(app).get('/');
    
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ message: 'API is running' });
  });

  test('GET /info returns info message', async () => {
    const response = await request(app).get('/info');
    
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ message: 'Info message logged' });
  });

  test('GET /warn returns warning message', async () => {
    const response = await request(app).get('/warn');
    
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ message: 'Warning message logged' });
  });

  test('GET /error returns error status and message', async () => {
    const response = await request(app).get('/error');
    
    expect(response.status).toBe(500);
    expect(response.body).toEqual({ error: 'Error message logged' });
  });

  test('GET /debug returns debug message', async () => {
    const response = await request(app).get('/debug');
    
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ message: 'Debug message logged' });
  });
});
