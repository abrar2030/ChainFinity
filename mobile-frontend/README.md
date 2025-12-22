# ChainFinity Mobile Frontend

A modern, responsive web application for managing cross-chain DeFi portfolios with risk management features.

## Tech Stack

- **Framework**: Next.js 15 with App Router
- **Language**: TypeScript
- **UI Library**: Material-UI (MUI) v7
- **Styling**: Tailwind CSS + MUI System
- **State Management**: React Context API
- **Blockchain**: Ethers.js v6
- **HTTP Client**: Axios
- **Animations**: Framer Motion
- **Testing**: Jest + React Testing Library

## Features

- 🔐 **Authentication**: Email/password and Web3 wallet authentication
- 📊 **Dashboard**: Real-time portfolio monitoring and risk analytics
- 💼 **Portfolio Management**: Track assets across multiple chains
- 📈 **Risk Assessment**: AI-powered risk analysis and alerts
- 🔄 **Transactions**: View and manage cross-chain transactions
- ⚙️ **Settings**: Comprehensive user preferences and security settings
- 🌓 **Dark Mode**: Full dark mode support
- 📱 **Responsive**: Mobile-first responsive design

## Prerequisites

- Node.js 18.x or higher
- pnpm 10.x (recommended) or npm/yarn
- A running instance of the ChainFinity backend

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/abrar2030/ChainFinity.git
cd ChainFinity/mobile-frontend
```

### 2. Install dependencies

```bash
# Using pnpm (recommended)
pnpm install

# Or using npm
npm install

# Or using yarn
yarn install
```

### 3. Configure environment variables

```bash
cp .env.example .env.local
```

Edit `.env.local` and configure the following variables:

```env
# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_API_VERSION=v1

# Blockchain Configuration
NEXT_PUBLIC_DEFAULT_CHAIN_ID=1
NEXT_PUBLIC_INFURA_ID=your_infura_project_id_here
NEXT_PUBLIC_ALCHEMY_API_KEY=your_alchemy_api_key_here

# Feature Flags
NEXT_PUBLIC_ENABLE_ANALYTICS=false
NEXT_PUBLIC_ENABLE_ERROR_REPORTING=false
```

## Running the Application

### Development Mode

```bash
# Using pnpm
pnpm dev

# Or using npm
npm run dev

# Or using yarn
yarn dev
```

The application will be available at [http://localhost:3000](http://localhost:3000)

### Production Build

```bash
# Build the application
pnpm build

# Start the production server
pnpm start
```

## Running with Backend

### 1. Start the Backend

Navigate to the backend directory and start the backend server:

```bash
cd ../code/backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Start the Frontend

In a new terminal:

```bash
cd mobile-frontend
pnpm dev
```

### 3. Access the Application

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

## Testing

### Run All Tests

```bash
pnpm test
```

### Run Tests in Watch Mode

```bash
pnpm test:watch
```

### Run Tests with Coverage

```bash
pnpm test -- --coverage
```

## Project Structure

```
mobile-frontend/
├── src/
│   ├── app/              # Next.js App Router pages
│   │   ├── dashboard/    # Dashboard page
│   │   ├── login/        # Login page
│   │   ├── register/     # Registration page
│   │   ├── settings/     # Settings page
│   │   ├── transactions/ # Transactions page
│   │   ├── layout.tsx    # Root layout
│   │   └── page.tsx      # Home page
│   ├── components/       # Reusable React components
│   │   ├── ui/          # Shadcn/ui components
│   │   └── ...          # Custom components
│   ├── context/         # React Context providers
│   │   └── AppContext.tsx
│   ├── services/        # API services
│   │   └── api.ts
│   ├── hooks/           # Custom React hooks
│   ├── lib/             # Utility functions
│   ├── types/           # TypeScript type definitions
│   └── __tests__/       # Test files
├── public/              # Static assets
├── .env.example         # Environment variables template
├── next.config.ts       # Next.js configuration
├── tailwind.config.ts   # Tailwind CSS configuration
├── tsconfig.json        # TypeScript configuration
└── package.json         # Project dependencies

```

## Common Issues & Solutions

### Issue: "Module not found" errors

**Solution**: Clear the cache and reinstall dependencies:

```bash
rm -rf node_modules .next
pnpm install
```

### Issue: Backend connection errors

**Solution**: Ensure the backend is running and the `NEXT_PUBLIC_API_URL` in `.env.local` is correct.

### Issue: Web3 wallet not connecting

**Solution**:

1. Ensure MetaMask or another Web3 wallet is installed
2. Check browser console for errors
3. Verify you're on a supported network

### Issue: Build errors

**Solution**: Check that all environment variables are properly set and the TypeScript types are correct.

## Development Guidelines

### Code Style

- Use TypeScript for type safety
- Follow the existing code structure and naming conventions
- Use functional components with hooks
- Write tests for new features

### Component Guidelines

- Keep components small and focused
- Use MUI components where possible
- Implement proper error boundaries
- Add loading states for async operations

### State Management

- Use React Context for global state
- Use local state for component-specific data
- Implement proper error handling

## API Integration

The frontend integrates with the following backend endpoints:

- **Auth**: `/api/v1/auth/*`
- **Portfolios**: `/api/v1/portfolios/*`
- **Transactions**: `/api/v1/transactions/*`
- **Risk**: `/api/v1/risk/*`
- **Blockchain**: `/api/v1/blockchain/*`

See the [API Documentation](http://localhost:8000/docs) for more details.

## Deployment

### Vercel (Recommended)

1. Push your code to GitHub
2. Import the project in Vercel
3. Configure environment variables
4. Deploy

### Docker

```bash
docker build -t chainfinity-mobile .
docker run -p 3000:3000 chainfinity-mobile
```

### Manual Deployment

```bash
pnpm build
pnpm start
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.
