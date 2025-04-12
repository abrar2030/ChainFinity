import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Container,
  Box,
  Typography,
  Button,
  Paper,
} from '@mui/material';

function NotFound() {
  const navigate = useNavigate();

  return (
    <Container maxWidth="sm">
      <Box
        sx={{
          marginTop: 8,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        <Paper
          elevation={3}
          sx={{
            padding: 4,
            width: '100%',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            textAlign: 'center',
          }}
        >
          <Typography variant="h1" component="h1" gutterBottom>
            404
          </Typography>
          <Typography variant="h5" gutterBottom>
            Page Not Found
          </Typography>
          <Typography color="text.secondary" paragraph>
            The page you are looking for doesn't exist or has been moved.
          </Typography>
          <Button
            variant="contained"
            color="primary"
            onClick={() => navigate('/')}
            sx={{ mt: 2 }}
          >
            Go to Homepage
          </Button>
        </Paper>
      </Box>
    </Container>
  );
}

export default NotFound; 