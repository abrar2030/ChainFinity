import React from 'react';
import { Box, Container, Typography, Link, Grid } from '@mui/material';

const Footer = () => {
  return (
    <Box
      component="footer"
      sx={{
        py: 3,
        px: 2,
        mt: 'auto',
        backgroundColor: (theme) => theme.palette.grey[100],
      }}
    >
      <Container maxWidth="lg">
        <Grid container spacing={4}>
          <Grid item xs={12} sm={4}>
            <Typography variant="h6" color="text.primary" gutterBottom>
              ChainFinity
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Empowering blockchain solutions for the future.
            </Typography>
          </Grid>
          <Grid item xs={12} sm={4}>
            <Typography variant="h6" color="text.primary" gutterBottom>
              Quick Links
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column' }}>
              <Link href="/" color="inherit" underline="hover">
                Home
              </Link>
              <Link href="/dashboard" color="inherit" underline="hover">
                Dashboard
              </Link>
              <Link href="/transactions" color="inherit" underline="hover">
                Transactions
              </Link>
            </Box>
          </Grid>
          <Grid item xs={12} sm={4}>
            <Typography variant="h6" color="text.primary" gutterBottom>
              Contact
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Email: support@chainfinity.com
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Twitter: @ChainFinity
            </Typography>
          </Grid>
        </Grid>
        <Box sx={{ mt: 3, textAlign: 'center' }}>
          <Typography variant="body2" color="text.secondary">
            © {new Date().getFullYear()} ChainFinity. All rights reserved.
          </Typography>
        </Box>
      </Container>
    </Box>
  );
};

export default Footer; 