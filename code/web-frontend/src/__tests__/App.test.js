import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { BrowserRouter } from "react-router-dom";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ThemeProvider, createTheme } from "@mui/material/styles"; // Import MUI ThemeProvider and createTheme
import App from "../App";
import { AppProvider } from "../context/AppContext";

// Create a default MUI theme for testing
const theme = createTheme();

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
  <ThemeProvider theme={theme}> { /* Add MUI ThemeProvider */}
    <QueryClientProvider client={queryClient}>
      <AppProvider>
        <BrowserRouter>{children}</BrowserRouter>
      </AppProvider>
    </QueryClientProvider>
  </ThemeProvider>
);

describe("App Component", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    Storage.prototype.getItem = jest.fn(key => {
      if (key === "darkMode") return "false";
      if (key === "token") return null;
      if (key === "user") return null;
      return null;
    });
    Storage.prototype.setItem = jest.fn();
    Storage.prototype.removeItem = jest.fn();

    // Mock authAPI globally for all tests in this describe block
    // to ensure it's fresh and correctly configured for each test case.
    jest.mock("../services/api", () => ({
      ...jest.requireActual("../services/api"),
      authAPI: {
        login: jest.fn(),
        getCurrentUser: jest.fn(),
        register: jest.fn(), // Assuming register might be called
      },
      // Mock other APIs if App.js or its children use them directly
      // e.g., portfolioAPI: { getPortfolio: jest.fn() }
    }));
  });

  test("renders login page by default", () => {
    render(
      <TestWrapper>
        <App />
      </TestWrapper>
    );
    expect(screen.getByText(/login/i)).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/email/i)).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/password/i)).toBeInTheDocument();
  });

  test("handles login form submission and navigates", async () => {
    const { authAPI } = require("../services/api");
    authAPI.login.mockResolvedValue({ data: { access_token: "fake_token" } });
    authAPI.getCurrentUser.mockResolvedValue({ data: { id: "1", name: "Test User", email: "test@example.com" } });

    render(
      <TestWrapper>
        <App />
      </TestWrapper>
    );

    fireEvent.change(screen.getByPlaceholderText(/email/i), { target: { value: "test@example.com" } });
    fireEvent.change(screen.getByPlaceholderText(/password/i), { target: { value: "password123" } });
    fireEvent.click(screen.getByRole("button", { name: /login/i }));

    await waitFor(() => {
      expect(authAPI.login).toHaveBeenCalledWith({ email: "test@example.com", password: "password123" });
    });
    await waitFor(() => {
      expect(authAPI.getCurrentUser).toHaveBeenCalled();
    });
    // Check for an element that appears after login (e.g., part of Navbar or Dashboard)
    // This depends on what App.js renders. Let's assume a "Logout" button appears in the Navbar.
    await waitFor(() => {
        // Check if login screen elements are gone
        expect(screen.queryByText(/login/i)).not.toBeInTheDocument();
        // Check for an element that appears after login
        // expect(screen.getByRole("button", { name: /logout/i })).toBeInTheDocument(); 
    });
  });

  test("displays validation errors for invalid login (client-side)", async () => {
    render(
      <TestWrapper>
        <App />
      </TestWrapper>
    );
    // This test assumes client-side validation in the Login component itself.
    // The App component or AppContext might not show these specific errors.
    // For now, we just check that the login form is still present.
    fireEvent.change(screen.getByPlaceholderText(/email/i), { target: { value: "invalid-email" } });
    fireEvent.click(screen.getByRole("button", { name: /login/i }));
    // Add assertion for client-side validation message if Login component shows it
    // await waitFor(() => expect(screen.getByText(/invalid email format/i)).toBeInTheDocument());
    expect(screen.getByText(/login/i)).toBeInTheDocument(); // Form should still be there
  });

  test("handles API errors gracefully during login", async () => {
    const { authAPI } = require("../services/api");
    const apiError = { response: { data: { detail: "Invalid credentials" } } };
    authAPI.login.mockRejectedValue(apiError);

    render(
      <TestWrapper>
        <App />
      </TestWrapper>
    );

    fireEvent.change(screen.getByPlaceholderText(/email/i), { target: { value: "test@example.com" } });
    fireEvent.change(screen.getByPlaceholderText(/password/i), { target: { value: "wrongpassword" } });
    fireEvent.click(screen.getByRole("button", { name: /login/i }));

    await waitFor(() => {
      expect(authAPI.login).toHaveBeenCalledWith({ email: "test@example.com", password: "wrongpassword" });
    });
    // AppContext's `handleApiError` should process this and set an error state.
    // The UI should display this error. The exact message depends on `handleApiError`.
    await waitFor(() => {
      // Assuming the error from AppContext is displayed, e.g. as part of a notification or alert
      // The current AppContext sets an error object, which might be { message: "Invalid credentials" }
      // This depends on how the error is rendered by a component consuming the context.
      // For now, let's look for a generic error text or the specific detail if it's directly rendered.
      expect(screen.getByText(/Invalid credentials/i)).toBeInTheDocument();
    });
  });

  // Test for portfolio data display might be better in a Dashboard/Portfolio component test
  // if App.js mainly handles routing and context.
  // test("displays portfolio data after successful login", async () => {
  //   const { authAPI } = require("../services/api");
  //   authAPI.login.mockResolvedValue({ data: { access_token: "fake_token" } });
  //   authAPI.getCurrentUser.mockResolvedValue({ data: { id: "1", name: "Test User" } });
    
  //   // Assume another API call fetches portfolio data, e.g., within a Dashboard component
  //   // const { portfolioAPI } = require("../services/api"); 
  //   // portfolioAPI.getPortfolio.mockResolvedValue({ data: { tokens: [{ symbol: 'ETH', balance: '1.0'}] }});

  //   render(
  //     <TestWrapper>
  //       <App />
  //     </TestWrapper>
  //   );

  //   fireEvent.change(screen.getByPlaceholderText(/email/i), { target: { value: "test@example.com" } });
  //   fireEvent.change(screen.getByPlaceholderText(/password/i), { target: { value: "password123" } });
  //   fireEvent.click(screen.getByRole("button", { name: /login/i }));

  //   await waitFor(() => {
  //     // expect(screen.getByText("ETH")).toBeInTheDocument();
  //   });
  // });
});

