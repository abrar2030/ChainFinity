import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import App from '../App';

// Create a new QueryClient for testing
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
});

// Wrapper component to provide necessary context
const TestWrapper = ({ children }) => (
  <QueryClientProvider client={queryClient}>
    <BrowserRouter>
      {children}
    </BrowserRouter>
  </QueryClientProvider>
);

describe('App Component', () => {
  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks();
  });

  test('renders login page by default', () => {
    render(
      <TestWrapper>
        <App />
      </TestWrapper>
    );
    
    expect(screen.getByText(/login/i)).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/email/i)).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/password/i)).toBeInTheDocument();
  });

  test('handles login form submission', async () => {
    render(
      <TestWrapper>
        <App />
      </TestWrapper>
    );

    const emailInput = screen.getByPlaceholderText(/email/i);
    const passwordInput = screen.getByPlaceholderText(/password/i);
    const submitButton = screen.getByRole('button', { name: /login/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    fireEvent.click(submitButton);

    await waitFor(() => {
      // Add assertions based on your login success behavior
      // For example, checking if user is redirected to dashboard
      expect(screen.queryByText(/login/i)).not.toBeInTheDocument();
    });
  });

  test('displays validation errors for invalid login', async () => {
    render(
      <TestWrapper>
        <App />
      </TestWrapper>
    );

    const emailInput = screen.getByPlaceholderText(/email/i);
    const passwordInput = screen.getByPlaceholderText(/password/i);
    const submitButton = screen.getByRole('button', { name: /login/i });

    // Test invalid email
    fireEvent.change(emailInput, { target: { value: 'invalid-email' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText(/invalid email/i)).toBeInTheDocument();
    });

    // Test short password
    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'short' } });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText(/password too short/i)).toBeInTheDocument();
    });
  });

  test('handles wallet connection', async () => {
    render(
      <TestWrapper>
        <App />
      </TestWrapper>
    );

    const connectWalletButton = screen.getByRole('button', { name: /connect wallet/i });
    fireEvent.click(connectWalletButton);

    await waitFor(() => {
      // Add assertions based on your wallet connection behavior
      expect(screen.getByText(/wallet connected/i)).toBeInTheDocument();
    });
  });

  test('displays portfolio data after successful login', async () => {
    // Mock successful login
    const mockPortfolioData = {
      tokens: [
        { symbol: 'ETH', balance: '1.5', value: '3000' },
        { symbol: 'USDT', balance: '1000', value: '1000' }
      ]
    };

    // Mock the API response
    global.fetch = jest.fn(() =>
      Promise.resolve({
        json: () => Promise.resolve(mockPortfolioData),
        ok: true
      })
    );

    render(
      <TestWrapper>
        <App />
      </TestWrapper>
    );

    // Perform login
    const emailInput = screen.getByPlaceholderText(/email/i);
    const passwordInput = screen.getByPlaceholderText(/password/i);
    const submitButton = screen.getByRole('button', { name: /login/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText('ETH')).toBeInTheDocument();
      expect(screen.getByText('USDT')).toBeInTheDocument();
      expect(screen.getByText('1.5')).toBeInTheDocument();
      expect(screen.getByText('1000')).toBeInTheDocument();
    });
  });

  test('handles API errors gracefully', async () => {
    // Mock API error
    global.fetch = jest.fn(() =>
      Promise.reject(new Error('API Error'))
    );

    render(
      <TestWrapper>
        <App />
      </TestWrapper>
    );

    // Perform login
    const emailInput = screen.getByPlaceholderText(/email/i);
    const passwordInput = screen.getByPlaceholderText(/password/i);
    const submitButton = screen.getByRole('button', { name: /login/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText(/error occurred/i)).toBeInTheDocument();
    });
  });

  test('handles network errors gracefully', async () => {
    // Mock network error
    global.fetch = jest.fn(() =>
      Promise.reject(new Error('Network Error'))
    );

    render(
      <TestWrapper>
        <App />
      </TestWrapper>
    );

    // Perform login
    const emailInput = screen.getByPlaceholderText(/email/i);
    const passwordInput = screen.getByPlaceholderText(/password/i);
    const submitButton = screen.getByRole('button', { name: /login/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText(/network error/i)).toBeInTheDocument();
    });
  });
}); 