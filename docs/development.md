# Development Guide

This guide provides information for developers contributing to the ChainFinity project.

## Development Environment Setup

1. Fork and clone the repository
2. Install dependencies:

```bash
npm install
```

3. Set up pre-commit hooks:

```bash
npm run prepare
```

## Code Style

We follow these coding standards:

- Use TypeScript for all new code
- Follow ESLint rules (see `.eslintrc`)
- Use Prettier for code formatting
- Write unit tests for new features

## Branching Strategy

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `release/*` - Release preparation

## Commit Guidelines

Follow the Conventional Commits specification:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes
- `refactor:` - Code refactoring
- `test:` - Test-related changes
- `chore:` - Maintenance tasks

## Testing

Run tests:

```bash
npm test
```

Run tests with coverage:

```bash
npm run test:coverage
```
