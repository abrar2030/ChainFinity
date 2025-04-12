import React, { useEffect, useState } from 'react';
import {
  Box,
  Container,
  Grid,
  Card,
  CardContent,
  Typography,
  Paper,
  CircularProgress,
  Alert,
} from '@mui/material';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { useApp } from '../context/AppContext';
import { formatTokenAmount, formatAddress } from '../utils/helpers';

const Dashboard = () => {
  const { state, actions } = useApp();
  const { wallet, user } = state;
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [portfolioData, setPortfolioData] = useState(null);

  useEffect(() => {
    const fetchPortfolioData = async () => {
      try {
        setLoading(true);
        setError(null);
        // TODO: Implement actual portfolio data fetching
        // This is a mock implementation
        const mockData = {
          totalValue: '1000.00',
          assets: [
            { symbol: 'ETH', amount: '1.5', value: '3000.00' },
            { symbol: 'BTC', amount: '0.1', value: '4000.00' },
          ],
          recentTransactions: [
            { type: 'buy', symbol: 'ETH', amount: '0.5', timestamp: Date.now() / 1000 },
            { type: 'sell', symbol: 'BTC', amount: '0.05', timestamp: Date.now() / 1000 - 3600 },
          ],
        };
        setPortfolioData(mockData);
      } catch (err) {
        setError('Failed to load portfolio data');
        console.error('Error fetching portfolio data:', err);
      } finally {
        setLoading(false);
      }
    };

    if (wallet.isConnected) {
      fetchPortfolioData();
    }
  }, [wallet.isConnected]);

  if (!wallet.isConnected) {
    return (
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Paper sx={{ p: 3, textAlign: 'center' }}>
          <Typography variant="h6" gutterBottom>
            Please connect your wallet to view your dashboard
          </Typography>
          <Box sx={{ mt: 2 }}>
            <button onClick={actions.connectWallet}>
              Connect Wallet
            </button>
          </Box>
        </Paper>
      </Container>
    );
  }

  if (loading) {
    return (
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          minHeight: '400px',
        }}
      >
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Alert severity="error">{error}</Alert>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Grid container spacing={3}>
        {/* Portfolio Overview */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Portfolio Overview
            </Typography>
            <Typography variant="h4" color="primary">
              ${portfolioData.totalValue}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Connected Wallet: {formatAddress(wallet.address)}
            </Typography>
          </Paper>
        </Grid>

        {/* Assets */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Your Assets
            </Typography>
            {portfolioData.assets.map((asset, index) => (
              <Box
                key={index}
                sx={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  mb: 2,
                }}
              >
                <Typography>{asset.symbol}</Typography>
                <Box>
                  <Typography>{formatTokenAmount(asset.amount)}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    ${asset.value}
                  </Typography>
                </Box>
              </Box>
            ))}
          </Paper>
        </Grid>

        {/* Recent Transactions */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Recent Transactions
            </Typography>
            {portfolioData.recentTransactions.map((tx, index) => (
              <Box
                key={index}
                sx={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  mb: 2,
                }}
              >
                <Typography
                  color={tx.type === 'buy' ? 'success.main' : 'error.main'}
                >
                  {tx.type.toUpperCase()}
                </Typography>
                <Typography>{formatTokenAmount(tx.amount)} {tx.symbol}</Typography>
                <Typography variant="body2" color="text.secondary">
                  {new Date(tx.timestamp * 1000).toLocaleTimeString()}
                </Typography>
              </Box>
            ))}
          </Paper>
        </Grid>
      </Grid>
    </Container>
  );
};

export default Dashboard; 