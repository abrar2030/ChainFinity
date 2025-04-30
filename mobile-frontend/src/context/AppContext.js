import React, { createContext, useState, useEffect, useContext } from 'react';
import { authAPI, handleApiError } from '../services/api';

// Create context
const AppContext = createContext();

// Provider component
export const AppProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [darkMode, setDarkMode] = useState(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('darkMode') === 'true';
    }
    return false; // Default to false on server
  });

  // Initialize auth state from localStorage on app load
  useEffect(() => {
    const initAuth = async () => {
      // Only run on client-side
      if (typeof window === 'undefined') {
        setLoading(false);
        return;
      }

      const token = localStorage.getItem('token');
      const storedUser = localStorage.getItem('user');
      
      if (token && storedUser) {
        try {
          setUser(JSON.parse(storedUser));
          setIsAuthenticated(true);
          
          // Verify token is still valid by fetching current user
          const response = await authAPI.getCurrentUser();
          setUser(response.data);
        } catch (err) {
          // Token is invalid or expired
          logout(); // logout clears localStorage
          setError(handleApiError(err));
        }
      }
      
      setLoading(false);
    };
    
    initAuth();
  }, []); // Empty dependency array ensures this runs only once on mount

  // Toggle dark mode
  const toggleTheme = () => {
    const newMode = !darkMode;
    setDarkMode(newMode);
    if (typeof window !== 'undefined') {
      localStorage.setItem('darkMode', newMode);
    }
  };

  // Login function
  const login = async (credentials) => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await authAPI.login(credentials);
      const { access_token, token_type } = response.data;
      
      // Store token
      localStorage.setItem('token', access_token);
      
      // Get user data
      const userResponse = await authAPI.getCurrentUser();
      setUser(userResponse.data);
      localStorage.setItem('user', JSON.stringify(userResponse.data));
      
      setIsAuthenticated(true);
      setLoading(false);
      return true;
    } catch (err) {
      setError(handleApiError(err));
      setLoading(false);
      return false;
    }
  };

  // Register function
  const register = async (userData) => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await authAPI.register(userData);
      setLoading(false);
      return { success: true, data: response.data };
    } catch (err) {
      const error = handleApiError(err);
      setError(error);
      setLoading(false);
      return { success: false, error };
    }
  };

  // Logout function
  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setUser(null);
    setIsAuthenticated(false);
  };

  // Clear error
  const clearError = () => {
    setError(null);
  };

  // Context value
  const value = {
    user,
    isAuthenticated,
    loading,
    error,
    darkMode,
    login,
    register,
    logout,
    clearError,
    toggleTheme
  };

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
};

// Custom hook to use the auth context
export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
};

export default AppContext;
