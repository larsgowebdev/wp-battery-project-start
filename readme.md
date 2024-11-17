# WP-Battery Project Starter Kit

Starter kit for WordPress development with WP-Battery: DDEV, Composer, Vite, basic GitLab CI/CD pipeline and more.

## Start a fresh project (recommended quickstart)

1. clone this repository into a new folder
```bash
git clone git@github.com:larsgowebdev/wp-battery-project-start.git my-new-project
```

2. change into the fresh folder
```bash
cd my-new-project
```

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

Your project should now have its basic files initialized.

### Setup ddev & install

1. start the project
```bash
ddev start
```

2. (optional) configure dependencies in composer.json

3. run composer install
```bash
ddev composer install
```

4. (optional) configure frontend npm dependencies in package.json

5. install dependencies
```bash
ddev exec 'npm install && npm run build'
```

Your site will be available at `https://[project-name].ddev.site`

### Connect to a fresh project git repository

1. disconnect it from the project-start git (make sure you are in the new project folder before you rm -rf)
```bash
rm -rf .git
```

2. create your preferred git repository (github, gitlab, etc.)

3. connect to the project git repository and initialize
```bash
git init
git remote add origin git@host:my/repo.git
git branch -M production
git add .
git commit -m "Initial commit"
git push -u origin production
```



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

#### Initial Deployment Setup

Before the first deployment, you need to set up the remote directory structure. Use the provided setup script (make it executable first)

```bash
chmod +x setup-remote-for-deployment.sh
```
```bash
./setup-remote-for-deployment.sh <environment>
```
Where `<environment>` is either `staging` or `production`.

The script will:
1. Read configuration from `.gitlab/config/<environment>.yml`
2. Create the required directory structure on the remote:
   ```
   deployment_staging/
   ├── cache/
   ├── releases/
   └── shared/
       ├── .env
       └── web/
           └── app/
               ├── languages/
               └── uploads/
   ```
3. Set appropriate permissions
4. Create an initial `.env` file if it doesn't exist

##### Configuration Requirements

Your environment configuration file (`.gitlab/config/<environment>.yml`) must contain:

```yaml
.<environment>_config:
  extends: .wp_defaults
  variables:
    DEPLOY_USER: "your-user"
    DEPLOY_SERVER: "your-server"
    DEPLOY_PATH: "/path/to/deployment"
    # ... other variables
```

Required variables:
- `DEPLOY_USER`: SSH user for deployment
- `DEPLOY_SERVER`: Target server hostname
- `DEPLOY_PATH`: Absolute path for deployment directory

##### Safety Features

The setup script includes several safety measures:
- Confirms all actions before execution
- Only creates directories/files if they don't exist
- Preserves existing `.env` files
- Shows detailed feedback for all operations
- Validates configuration before proceeding

##### Example Usage

```bash
# Set up staging environment
./setup-remote-for-deployment.sh staging

# Set up production environment
./setup-remote-for-deployment.sh production
```

## Notes

- Keep sensitive credentials out of version control
- Always work with environment variables for configuration
- Use the provided `.gitignore` rules