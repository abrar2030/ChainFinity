import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { blockchainService, backendService } from '../services/api';

const AppContext = createContext();

const initialState = {
  user: null,
  wallet: {
    address: null,
    balance: '0',
    isConnected: false,
  },
  loading: false,
  error: null,
};

function appReducer(state, action) {
  switch (action.type) {
    case 'SET_USER':
      return { ...state, user: action.payload };
    case 'SET_WALLET':
      return { ...state, wallet: { ...state.wallet, ...action.payload } };
    case 'SET_LOADING':
      return { ...state, loading: action.payload };
    case 'SET_ERROR':
      return { ...state, error: action.payload };
    case 'RESET_STATE':
      return initialState;
    default:
      return state;
  }
}

export function AppProvider({ children }) {
  const [state, dispatch] = useReducer(appReducer, initialState);

  useEffect(() => {
    // Check if user is logged in
    const token = localStorage.getItem('token');
    if (token) {
      fetchUserData();
    }
  }, []);

  const fetchUserData = async () => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      const userData = await backendService.getUserData();
      dispatch({ type: 'SET_USER', payload: userData });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error.message });
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  };

  const connectWallet = async () => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      if (!window.ethereum) {
        throw new Error('Please install MetaMask');
      }

      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts',
      });

      const address = accounts[0];
      const balance = await blockchainService.getBalance(address);

      dispatch({
        type: 'SET_WALLET',
        payload: {
          address,
          balance,
          isConnected: true,
        },
      });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error.message });
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  };

  const disconnectWallet = () => {
    dispatch({
      type: 'SET_WALLET',
      payload: {
        address: null,
        balance: '0',
        isConnected: false,
      },
    });
  };

  const login = async (credentials) => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      const response = await backendService.login(credentials);
      dispatch({ type: 'SET_USER', payload: response.user });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error.message });
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  };

  const logout = () => {
    localStorage.removeItem('token');
    dispatch({ type: 'RESET_STATE' });
  };

  const value = {
    state,
    actions: {
      connectWallet,
      disconnectWallet,
      login,
      logout,
      fetchUserData,
    },
  };

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
} 