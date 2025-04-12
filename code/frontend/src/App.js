import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';
import { AppProvider } from './context/AppContext';
import { theme, globalStyles } from './styles/globalStyles';
import { Global } from '@emotion/react';
import Web3Wrapper from '../web3-provider';

// Import pages
import Home from './pages/Home';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import NotFound from './pages/NotFound';

// Import components
import Navbar from './components/Navbar';
import Footer from './components/Footer';

function App() {
  return (
    <Web3Wrapper>
      <AppProvider>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <Global styles={globalStyles} />
          <Router>
            <div className="app">
              <Navbar />
              <main className="container">
                <Routes>
                  <Route path="/" element={<Home />} />
                  <Route path="/dashboard" element={<Dashboard />} />
                  <Route path="/login" element={<Login />} />
                  <Route path="*" element={<NotFound />} />
                </Routes>
              </main>
              <Footer />
            </div>
          </Router>
        </ThemeProvider>
      </AppProvider>
    </Web3Wrapper>
  );
}

export default App; 