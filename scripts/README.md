# ChainFinity Automation Scripts

This package contains a collection of automation scripts designed to enhance the development, testing, deployment, and monitoring workflows for the ChainFinity project.

## Overview

These scripts address various automation opportunities identified in the ChainFinity repository, focusing on:

1. CI/CD Pipeline Enhancement
2. Environment Setup Automation
3. Testing Automation
4. Monitoring and Alerting
5. Deployment Orchestration

## Scripts Included

### 1. CI/CD Pipeline (`ci-cd.yml`)

A comprehensive GitHub Actions workflow that implements continuous integration and deployment for all components of the ChainFinity platform.

**Features:**

- Automated linting, testing, and security scanning
- Multi-component build process
- Environment-specific deployments
- Slack notifications

**Usage:**

1. Place this file in the `.github/workflows/` directory of your repository
2. Configure necessary secrets in your GitHub repository settings
3. Push changes to trigger the workflow

### 2. Enhanced Environment Setup (`env_setup.sh`)

An improved setup script that automates the environment configuration process for ChainFinity development.

**Features:**

- Automated dependency installation
- Environment-specific configuration
- Database setup
- Error handling and logging

**Usage:**

```bash
./env_setup.sh [options]

Options:
  --project-dir DIR       Set project directory (default: current directory)
  --node-version VERSION  Set Node.js version (default: 18)
  --python-version VERSION Set Python version (default: 3.11)
  --skip-docker           Skip Docker installation
  --skip-databases        Skip database setup
  --environment ENV       Set environment (development, staging, production)
  --help                  Show help message
```

### 3. Monitoring Script (`monitor_chainfinity.sh`)

A comprehensive monitoring solution for the ChainFinity platform that tracks system health, services, and blockchain components.

**Features:**

- System resource monitoring
- Docker container health checks
- Database monitoring
- API endpoint validation
- Blockchain node status checks
- Automated reporting and alerting

**Usage:**

```bash
./monitor_chainfinity.sh [options]

Options:
  --config FILE           Configuration file path (default: monitor_config.json)
  --log-dir DIR           Log directory (default: ./logs)
  --alert-threshold NUM   Alert threshold percentage (default: 80)
  --check-interval SEC    Check interval in seconds (default: 300)
  --report-interval SEC   Report interval in seconds (default: 86400)
  --slack-webhook URL     Slack webhook URL for notifications
  --email ADDRESS         Email address for notifications
  --help                  Show help message
```

### 4. Testing Automation (`test_chainfinity.sh`)

A script that automates the testing process for all components of the ChainFinity platform.

**Features:**

- Component-specific testing
- Coverage reporting
- Parallel test execution
- HTML report generation

**Usage:**

```bash
./test_chainfinity.sh [options]

Options:
  --project-dir DIR        Set project directory (default: current directory)
  --log-dir DIR            Log directory (default: ./logs)
  --report-dir DIR         Test report directory (default: ./test-reports)
  --timeout SEC            Test timeout in seconds (default: 300)
  --no-parallel            Disable parallel testing
  --coverage-threshold NUM Minimum code coverage percentage (default: 80)
  --component NAME         Test only specific component (blockchain, backend, frontend, all)
  --help                   Show help message
```

### 5. Deployment Orchestration (`deploy_chainfinity.sh`)

A script that automates the deployment process for all components of the ChainFinity platform.

**Features:**

- Environment-specific deployments
- Component backups before deployment
- Infrastructure provisioning
- Deployment reporting

**Usage:**

```bash
./deploy_chainfinity.sh [options]

Options:
  --project-dir DIR     Set project directory (default: current directory)
  --log-dir DIR         Log directory (default: ./logs)
  --env-file FILE       Environment file (default: .env)
  --environment ENV     Deployment environment (development, staging, production)
  --backup-dir DIR      Backup directory (default: ./backups/YYYYMMDD_HHMMSS)
  --dry-run             Perform a dry run without making changes
  --component NAME      Deploy only specific component (blockchain, backend, frontend, all)
  --help                Show help message
```

## Installation

1. Extract the zip file to a directory of your choice
2. Make the scripts executable:
   ```bash
   chmod +x *.sh
   ```
3. Copy the CI/CD workflow file to your repository:
   ```bash
   mkdir -p .github/workflows/
   cp ci-cd.yml .github/workflows/
   ```

## Requirements

- Bash shell environment
- Git
- Node.js and npm
- Python 3.x
- Docker and Docker Compose (for certain features)
- AWS CLI (for deployment features)

## Best Practices

1. **Always review scripts** before running them in your environment
2. **Test in development** before using in production
3. **Backup your data** before running deployment scripts
4. **Customize configuration** files to match your specific needs
5. **Monitor logs** for any errors or warnings

## Support

For questions or issues with these scripts, please open an issue in the ChainFinity repository.
