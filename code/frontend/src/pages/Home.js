import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Container,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
  useTheme,
} from '@mui/material';
import { useApp } from '../context/AppContext';

function Home() {
  const theme = useTheme();
  const navigate = useNavigate();
  const { state } = useApp();
  const { wallet } = state;

  const features = [
    {
      title: 'AI-Powered Analysis',
      description: 'Get intelligent insights and predictions for your DeFi investments.',
    },
    {
      title: 'Real-time Monitoring',
      description: 'Track your portfolio performance in real-time across multiple chains.',
    },
    {
      title: 'Smart Alerts',
      description: 'Receive notifications for important market movements and opportunities.',
    },
  ];

  return (
    <Box>
      {/* Hero Section */}
      <Box
        sx={{
          bgcolor: 'background.paper',
          pt: 8,
          pb: 6,
        }}
      >
        <Container maxWidth="lg">
          <Grid container spacing={4} alignItems="center">
            <Grid item xs={12} md={6}>
              <Typography
                component="h1"
                variant="h2"
                color="text.primary"
                gutterBottom
              >
                Welcome to ChainFinity
              </Typography>
              <Typography
                variant="h5"
                color="text.secondary"
                paragraph
              >
                The next generation of DeFi analytics powered by artificial intelligence.
                Make smarter investment decisions with our advanced predictive models.
              </Typography>
              <Box sx={{ mt: 4 }}>
                {!wallet.isConnected ? (
                  <Button
                    variant="contained"
                    color="primary"
                    size="large"
                    onClick={() => navigate('/dashboard')}
                  >
                    Get Started
                  </Button>
                ) : (
                  <Button
                    variant="contained"
                    color="primary"
                    size="large"
                    onClick={() => navigate('/dashboard')}
                  >
                    Go to Dashboard
                  </Button>
                )}
              </Box>
            </Grid>
            <Grid item xs={12} md={6}>
              <Box
                component="img"
                sx={{
                  width: '100%',
                  borderRadius: 2,
                  boxShadow: 3,
                }}
                src="/hero-image.png"
                alt="ChainFinity Platform"
              />
            </Grid>
          </Grid>
        </Container>
      </Box>

      {/* Features Section */}
      <Container maxWidth="lg" sx={{ py: 8 }}>
        <Typography
          variant="h3"
          align="center"
          color="text.primary"
          gutterBottom
        >
          Key Features
        </Typography>
        <Grid container spacing={4} sx={{ mt: 4 }}>
          {features.map((feature, index) => (
            <Grid item key={index} xs={12} sm={6} md={4}>
              <Card
                sx={{
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  transition: 'transform 0.2s',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                  },
                }}
              >
                <CardContent>
                  <Typography
                    gutterBottom
                    variant="h5"
                    component="h2"
                  >
                    {feature.title}
                  </Typography>
                  <Typography>
                    {feature.description}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Container>
    </Box>
  );
}

export default Home; 