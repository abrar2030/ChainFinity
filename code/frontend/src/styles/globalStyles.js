import { createTheme } from '@mui/material/styles';

export const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
      light: '#42a5f5',
      dark: '#1565c0',
    },
    secondary: {
      main: '#9c27b0',
      light: '#ba68c8',
      dark: '#7b1fa2',
    },
    background: {
      default: '#f5f5f5',
      paper: '#ffffff',
    },
    error: {
      main: '#d32f2f',
    },
    success: {
      main: '#2e7d32',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
    h1: {
      fontSize: '2.5rem',
      fontWeight: 500,
    },
    h2: {
      fontSize: '2rem',
      fontWeight: 500,
    },
    h3: {
      fontSize: '1.75rem',
      fontWeight: 500,
    },
    h4: {
      fontSize: '1.5rem',
      fontWeight: 500,
    },
    h5: {
      fontSize: '1.25rem',
      fontWeight: 500,
    },
    h6: {
      fontSize: '1rem',
      fontWeight: 500,
    },
  },
  shape: {
    borderRadius: 8,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          borderRadius: 8,
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        },
      },
    },
  },
});

export const globalStyles = {
  '*': {
    margin: 0,
    padding: 0,
    boxSizing: 'border-box',
  },
  html: {
    fontSize: '16px',
  },
  body: {
    fontFamily: theme.typography.fontFamily,
    backgroundColor: theme.palette.background.default,
    color: theme.palette.text.primary,
    lineHeight: 1.5,
  },
  '#root': {
    minHeight: '100vh',
    display: 'flex',
    flexDirection: 'column',
  },
  a: {
    color: theme.palette.primary.main,
    textDecoration: 'none',
    '&:hover': {
      textDecoration: 'underline',
    },
  },
  '.container': {
    maxWidth: '1200px',
    margin: '0 auto',
    padding: '0 1rem',
  },
  '.flex-center': {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  '.text-center': {
    textAlign: 'center',
  },
  '.mt-1': { marginTop: '0.25rem' },
  '.mt-2': { marginTop: '0.5rem' },
  '.mt-3': { marginTop: '1rem' },
  '.mt-4': { marginTop: '1.5rem' },
  '.mt-5': { marginTop: '2rem' },
  '.mb-1': { marginBottom: '0.25rem' },
  '.mb-2': { marginBottom: '0.5rem' },
  '.mb-3': { marginBottom: '1rem' },
  '.mb-4': { marginBottom: '1.5rem' },
  '.mb-5': { marginBottom: '2rem' },
}; 