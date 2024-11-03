# WP-Battery Project Starter Kit

Starter kit for WordPress development with WP-Battery: DDEV, Composer, Vite, basic GitLab CI/CD pipeline and.

## Project Structure

```
.
├── .ddev/                      # DDEV configuration
│   ├── config.yaml             # Main DDEV configuration
│   └── docker-compose.*.yaml   # Additional DDEV configurations
├── .gitlab/                    # GitLab CI/CD configuration
│   ├── config/
│   │   ├── production.yml      # Production deployment config
│   │   └── staging.yml        # Staging deployment config
│   └── workflows/             # GitLab CI/CD workflow definitions
├── config/                    # WordPress configuration
│   ├── environments/         # Environment-specific configurations
│   └── application.php       # Main WordPress config
├── frontend/                 # Frontend asset sources
│   ├── fonts/               # Custom fonts
│   ├── images/              # Source images
│   ├── js/                  # JavaScript source files
│   ├── scss/               # SASS source files
│   └── vite.entry.js       # Vite entry point
├── migration/               # Database migration scripts
│   └── replacements/       # URL/path replacement rules
├── packages/               # WordPress packages
│   ├── mu-plugins/        # Must-use plugins
│   ├── plugins/           # Regular plugins
│   └── themes/            # Custom themes
├── web/                   # WordPress core (document root)
│   ├── wp/               # WordPress core files
│   ├── wp-config.php     # WordPress configuration
│   └── index.php         # Entry point
├── .env.example          # Environment variables template
├── .gitignore           # Git ignore rules
├── auth.json.example    # Composer authentication template
├── composer.json        # PHP dependencies
├── package.json         # NPM dependencies
├── vite.config.js       # Vite configuration
├── wp-cli.yml          # WP-CLI configuration
└── setup.sh            # Project setup script
```

## Key Files

- `.ddev/config.yaml`: DDEV configuration for local development
- `.env.example`: Template for environment variables (database, WP salts, etc.)
- `auth.json.example`: Template for ACF Pro credentials
- `vite.config.js`: Build configuration for frontend assets
- `composer.json`: PHP dependencies and WordPress installer configuration
- `.gitlab-ci.yml`: CI/CD pipeline configuration
- `setup.sh`: Automated project setup script

## Setup Script

The `setup.sh` script automates the initial project setup process. It handles:

1. Project naming and configuration
2. DDEV environment setup
3. Environment variables configuration
4. WordPress salts generation
5. Theme setup and customization
6. Composer configuration
7. Frontend build setup
8. Deployment configuration

### Using the Setup Script

1. Make the script executable:
   ```bash
   chmod +x setup.sh
   ```

2. Run the script:
   ```bash
   ./setup.sh
   ```

3. Follow the prompts to configure:
    - Project name
    - Vendor name
    - Theme name
    - PHP version
    - Database type
    - ACF Pro credentials (optional)
    - Deployment settings (optional)

### After Setup

Once the script completes, initialize your development environment:

```bash
ddev start
ddev composer install
ddev exec 'npm install && npm run build'
```

Your site will be available at `https://[project-name].ddev.site`

## Development

### Frontend Development

- Assets are processed using Vite
- Run `npm run dev` for development
- Run `npm run build` for production build

### Local Development

- Uses DDEV for containerized development
- PHP version and database can be configured in `.ddev/config.yaml`
- Environment variables are stored in `.env`

### Deployment

Deployment is handled through GitLab CI/CD pipelines:

- Staging: Triggered on merge to `staging` branch
- Production: Triggered on merge to `production` branch

Configure deployment settings in:
- `.gitlab/config/staging.yml`
- `.gitlab/config/production.yml`

## Requirements

- DDEV
- Docker
- Git

## Notes

- Keep sensitive credentials out of version control
- Always work with environment variables for configuration
- Use the provided `.gitignore` rules