import axios from 'axios';
import { ethers } from 'ethers';

const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || 'http://localhost:8000';

// Create axios instance with default config
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add request interceptor for error handling
api.interceptors.request.use(
  (config) => {
    // Add auth token if exists
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Add response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response) {
      // Handle different HTTP error statuses
      switch (error.response.status) {
        case 401:
          // Handle unauthorized access
          localStorage.removeItem('token');
          window.location.href = '/login';
          break;
        case 403:
          // Handle forbidden access
          console.error('Access forbidden');
          break;
        case 404:
          // Handle not found
          console.error('Resource not found');
          break;
        case 500:
          // Handle server error
          console.error('Server error');
          break;
        default:
          console.error('API error:', error);
      }
    } else if (error.request) {
      // Handle network errors
      console.error('Network error:', error.request);
    } else {
      // Handle other errors
      console.error('Error:', error.message);
    }
    return Promise.reject(error);
  }
);

// Blockchain service functions
export const blockchainService = {
  async getBalance(address) {
    try {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const balance = await provider.getBalance(address);
      return ethers.utils.formatEther(balance);
    } catch (error) {
      console.error('Error getting balance:', error);
      throw error;
    }
  },

  async getTransactionHistory(address) {
    try {
      const response = await api.get(`/transactions/${address}`);
      return response.data;
    } catch (error) {
      console.error('Error getting transaction history:', error);
      throw error;
    }
  },
};

// Backend API service functions
export const backendService = {
  async login(credentials) {
    try {
      const response = await api.post('/auth/login', credentials);
      localStorage.setItem('token', response.data.token);
      return response.data;
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  },

  async getUserData() {
    try {
      const response = await api.get('/user/profile');
      return response.data;
    } catch (error) {
      console.error('Error getting user data:', error);
      throw error;
    }
  },

  async updateUserData(data) {
    try {
      const response = await api.put('/user/profile', data);
      return response.data;
    } catch (error) {
      console.error('Error updating user data:', error);
      throw error;
    }
  },
};

export default api; 