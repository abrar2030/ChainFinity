# ChainFinity Web Frontend

A modern React-based web application for cross-chain DeFi risk management and portfolio tracking.

## Features

- ✅ **Multi-Chain Portfolio Tracking**: Track assets across multiple blockchain networks
- ✅ **Transaction Management**: View, filter, and export transaction history
- ✅ **User Authentication**: Secure login and registration with JWT tokens
- ✅ **Responsive Design**: Mobile-friendly UI with Material-UI components
- ✅ **Real-time Data**: Live portfolio and transaction updates
- ✅ **Theme Support**: Light and dark mode support

## Prerequisites

- Node.js >= 16.0.0
- npm >= 7.0.0
- Backend API running on `http://localhost:8000` (or configure via environment variables)

## Installation

1. Clone the repository:

```bash
git clone https://github.com/abrar2030/ChainFinity.git
cd ChainFinity/web-frontend
```

2. Install dependencies:

```bash
npm ci
```

3. Create environment file:

```bash
cp .env.example .env
```

4. Update the `.env` file with your configuration:

```env
REACT_APP_API_URL=http://localhost:8000
```

## Available Scripts

### `npm start`

Runs the app in development mode. Open [http://localhost:3000](http://localhost:3000) to view it in your browser.

### `npm test`

Launches the test runner in interactive watch mode.

### `npm run build`

Builds the app for production to the `build` folder. The build is minified and optimized for best performance.

### `npm run test:coverage`

Runs tests and generates coverage report.

## Project Structure

```
web-frontend/
├── public/                # Static files
├── src/
│   ├── components/        # Reusable components
│   │   ├── layout/        # Layout components (Navbar, Footer)
│   │   ├── governance/    # Governance-related components
│   │   └── ...
│   ├── context/           # React Context providers
│   ├── hooks/             # Custom React hooks
│   ├── pages/             # Page components
│   ├── services/          # API services
│   ├── styles/            # Global styles
│   ├── utils/             # Utility functions
│   ├── App.js             # Main App component
│   └── index.js           # Entry point
├── package.json
└── README.md
```

## Backend Integration

The frontend expects the following backend API endpoints:

### Authentication

- `POST /api/auth/register` - User registration
- `POST /api/auth/token` - User login
- `GET /api/auth/me` - Get current user

### Blockchain

- `GET /api/blockchain/portfolio/:walletAddress` - Get portfolio data
- `GET /api/blockchain/transactions/:walletAddress` - Get transaction history
- `GET /api/blockchain/balance/:tokenAddress` - Get token balance
- `GET /api/blockchain/eth-balance` - Get ETH balance

## Running with Backend

1. Start the backend server (from the repository root):

```bash
cd code/backend
pip install -r requirements.txt
uvicorn app:app --reload
```

2. In a new terminal, start the frontend:

```bash
cd web-frontend
npm start
```

3. Access the application at `http://localhost:3000`

## Testing

The project includes comprehensive unit and integration tests:

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# Run tests in watch mode
npm run test:watch
```

## Environment Variables

| Variable                     | Description           | Default                 |
| ---------------------------- | --------------------- | ----------------------- |
| `REACT_APP_API_URL`          | Backend API URL       | `http://localhost:8000` |
| `REACT_APP_ETHEREUM_RPC_URL` | Ethereum RPC endpoint | -                       |
| `REACT_APP_POLYGON_RPC_URL`  | Polygon RPC endpoint  | -                       |
| `REACT_APP_CHAIN_ID`         | Default chain ID      | `1`                     |

## License

This project is licensed under the MIT License.
