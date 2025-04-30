import axios from 'axios';

// Create an axios instance with default config
const api = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://localhost:8000',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add a request interceptor to include auth token in requests
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Add a response interceptor to handle common errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    // Handle 401 Unauthorized errors (token expired or invalid)
    if (error.response && error.response.status === 401) {
      // Clear local storage and redirect to login
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Auth API endpoints
export const authAPI = {
  register: (userData) => api.post('/api/auth/register', userData),
  login: (credentials) => api.post('/api/auth/token', credentials),
  getCurrentUser: () => api.get('/api/auth/me'),
};

// Blockchain API endpoints
export const blockchainAPI = {
  getPortfolio: (walletAddress) => api.get(`/api/blockchain/portfolio/${walletAddress}`),
  getTransactions: (walletAddress) => api.get(`/api/blockchain/transactions/${walletAddress}`),
  getTokenBalance: (tokenAddress, network = 'ethereum') => 
    api.get(`/api/blockchain/balance/${tokenAddress}?network=${network}`),
  getEthBalance: () => api.get('/api/blockchain/eth-balance'),
};

// Helper function to handle API errors
export const handleApiError = (error) => {
  if (error.response) {
    // The request was made and the server responded with a status code
    // that falls out of the range of 2xx
    const { status, data } = error.response;
    return {
      status,
      message: data.detail || 'An error occurred',
    };
  } else if (error.request) {
    // The request was made but no response was received
    return {
      status: 0,
      message: 'No response from server. Please check your connection.',
    };
  } else {
    // Something happened in setting up the request that triggered an Error
    return {
      status: 0,
      message: error.message || 'An unknown error occurred',
    };
  }
};

export default api;
