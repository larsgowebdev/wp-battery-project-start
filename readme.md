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

### Notes

- Keep sensitive credentials out of version control
- Always work with environment variables for configuration
- Use the provided `.gitignore` rules

----

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

----

### Database Migration Scripts

Two scripts are provided to help with WordPress database migrations between environments (e.g., production to development, staging to development). They handle database exports, imports, and automatically replace environment-specific values (like URLs and file paths) using replacement patterns.

#### Prerequisites

- DDEV environment
- WP-CLI
- MySQL client tools
- CSV files containing search/replace patterns in `/migration/replacements/`
- SSH access to remote environments

#### Directory Structure

```
/migration/
├── _temp/         # Temporary files
├── backup/        # Database backups
├── export/        # Exported databases
├── import/        # Import source files
└── replacements/  # Search/replace pattern files
    ├── production-to-development.csv
    ├── production-to-staging.csv
    ├── staging-to-development.csv
    └── ...
```

#### Replacement Pattern Files

Create CSV files in the `replacements` directory with search and replace patterns. Name format: `{source}-to-{target}.csv`

Example `production-to-development.csv`:
```csv
https://production.com,https://development.test
/var/www/production/,/var/www/development/
```

#### Export Script: wp-export-db

Exports a database while performing environment-specific replacements.

```bash
ddev wp-export-db <source> <target> <export-filename>
```

Example:
```bash
ddev wp-export-db development production db_for_production.sql
```

The script will:
1. Create a backup of your current database
2. Perform all replacements specified in the pattern file
3. Export the modified database
4. Restore your local database to its original state

#### Import Script: wp-import-db

Imports a database while performing environment-specific replacements.

```bash
ddev wp-import-db <source> <target> <import-filename>
```

Example:
```bash
ddev wp-import-db production development db_production.sql
```

The script will:
1. Create a backup of your current database
2. Import the source database
3. Perform all replacements specified in the pattern file

#### Pull Database Script: wp-pull-db

Pulls a database from a remote environment and imports it locally.

```bash
ddev wp-pull-db <environment> [--skip-backup]
```

Example:
```bash
ddev wp-pull-db staging
ddev wp-pull-db production --skip-backup
```

The script will:
1. Connect to the remote server specified in your environment configuration
2. Create a dump of the remote database
3. Download the dump to your local machine
4. Import the database using wp-import-db
5. Perform environment-specific replacements automatically

#### Push Database Script: wp-push-db

Pushes your local database to a remote environment after performing necessary replacements.

```bash
ddev wp-push-db <environment>
```

Example:
```bash
ddev wp-push-db staging
```

The script will:
1. Create a backup of the remote database
2. Export your local database with environment-specific replacements
3. Upload the prepared database to the remote server
4. Import the database on the remote server

**Note:** This script requires explicit confirmation by typing "yes, push to <environment>" due to its potentially destructive nature.

#### Pull User-Generated Content: wp-pull-ugc

Synchronizes user-generated content (uploads) from a remote environment to your local environment.

```bash
ddev wp-pull-ugc <environment>
```

Example:
```bash
ddev wp-pull-ugc staging
```

The script will:
1. Connect to the remote server
2. Sync files from the remote uploads directory
3. Only download new or modified files
4. Preserve your local files

Uses rsync with delta-transfer algorithm for efficient file transfer.

#### Push User-Generated Content: wp-push-ugc

Pushes your local user-generated content to a remote environment.

```bash
ddev wp-push-ugc <environment>
```

Example:
```bash
ddev wp-push-ugc staging
```

The script will:
1. Push your local uploads to the remote environment
2. Only upload new or modified files
3. Update remote files if local versions are newer

**Note:** Like wp-push-db, this script requires explicit confirmation due to its potential to modify remote content.

#### Safety Features

All scripts include several safety measures:
- Confirmation prompts before execution (extra strict for push operations)
- Automatic backup creation
- Validation of all required files and directories
- Error handling with automatic rollback
- Detailed progress feedback
- Verification of file contents and permissions
- Protection against empty or invalid files
- SSH connection testing
- Remote environment validation

#### Example Workflows

1. **Initial Development Setup:**
   ```bash
   # Pull database and content from production
   ddev wp-pull-db production
   ddev wp-pull-ugc production
   ```

2. **Sync Staging Environment:**
   ```bash
   # Push local changes to staging
   ddev wp-push-db staging
   ddev wp-push-ugc staging
   ```

3. **Update Local Environment:**
   ```bash
   # Get latest content from staging
   ddev wp-pull-db staging
   ddev wp-pull-ugc staging
   ```

4. **Production Deployment:**
   ```bash
   # Carefully push changes to production
   ddev wp-push-db production
   ddev wp-push-ugc production
   ```

#### Environment Configuration

All scripts rely on environment configuration files located in `.gitlab/config/<environment>.yml`. These files should contain:
- DEPLOY_USER
- DEPLOY_SERVER
- DEPLOY_PATH

Example configuration:
```yaml
DEPLOY_USER: "username"
DEPLOY_SERVER: "example.com"
DEPLOY_PATH: "/path/to/deployment"
```

#### Error Recovery

If a script fails during execution:
1. Check the error message for details
2. A backup of your database before the operation can be found in `/migration/backup/`
3. The backup filename includes the timestamp: `backup-{environment}-{timestamp}.sql`
4. You can manually restore using the backup if needed

#### Notes

- Always verify the replacement patterns in your CSV files before running the scripts
- Keep backups before performing any database operations
- Test imports/exports with staging environment first
- Large databases might take longer to process
- Scripts require appropriate MySQL permissions
