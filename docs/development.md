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

## Pull Request Process

1. Create a feature branch
2. Make your changes
3. Run tests and ensure they pass
4. Update documentation if needed
5. Submit a pull request
6. Address review comments
7. Get approval from at least one maintainer

## Documentation

- Keep documentation up to date
- Add comments for complex logic
- Update README files when adding new features

## Release Process

1. Create a release branch
2. Update version numbers
3. Update changelog
4. Create a pull request
5. Get approval
6. Merge and tag the release

## Need Help?

- Check the [Architecture Guide](./architecture.md)
- Review the [API Documentation](./api-spec.md)
- Join our [Discord Community](https://discord.gg/chainfinity)
