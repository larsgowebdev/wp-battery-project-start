#!/bin/bash

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Available versions - easy to extend
PHP_VERSIONS=(
    "8.3"
    "8.2"
    "8.1"
    "8.0"
    "7.4"
)

DB_VERSIONS=(
    "mariadb:10.11"
    "mariadb:10.4"
    "mysql:8.0"
    "mysql:5.7"
)

# Default versions
DEFAULT_PHP="8.3"
DEFAULT_DB="mariadb:10.11"

# Helper functions
print_step() {
    echo -e "\n${BLUE}${BOLD}$1${NC}"
}

print_success() {
    echo -e "${GREEN}${BOLD}$1${NC}"
}

print_error() {
    echo -e "${RED}${BOLD}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${BOLD}$1${NC}"
}

# Validation function for names
validate_name() {
    local name=$1
    local type=$2
    if ! [[ $name =~ ^[a-z0-9-]+$ ]]; then
        print_error "Error: $type name can only contain lowercase letters, numbers, and hyphens"
        return 1
    fi
    return 0
}

# File existence check with confirmation
check_file_exists() {
    local file=$1
    if [ -e "$file" ]; then
        print_warning "Warning: $file already exists!"
        read -p "Do you want to overwrite it? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    return 0
}

# WordPress-compatible salt generation
# Uses the same character set as wp_generate_password() function
generate_salt() {
    local length=64
    local chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_ []{}<>~`+=,.;:/?|'
    local salt=""

    # Use /dev/urandom for cryptographically secure generation
    for (( i=1; i<=$length; i++ )); do
        local random_char=$(LC_ALL=C tr -dc "$chars" < /dev/urandom | head -c 1)
        salt="$salt$random_char"
    done
    echo "$salt"
}

# Prompt for project information with validation
while true; do
    read -p "Project name (lowercase letters, numbers, and hyphens only): " PROJECT_NAME
    if validate_name "$PROJECT_NAME" "Project"; then
        break
    fi
done

while true; do
    read -p "Vendor name (lowercase letters, numbers, and hyphens only): " VENDOR_NAME
    if validate_name "$VENDOR_NAME" "Vendor"; then
        break
    fi
done

while true; do
    read -p "Theme name (lowercase letters, numbers, and hyphens only): " THEME_NAME
    if validate_name "$THEME_NAME" "Theme"; then
        break
    fi
done

# DDEV Configuration
echo -e "\n${BOLD}DDEV Configuration${NC}"
echo "Available PHP versions:"
select PHP_VERSION in "${PHP_VERSIONS[@]}"; do
    if [ -n "$PHP_VERSION" ]; then
        break
    fi
    echo "Please select a valid option"
done

echo "Available database versions:"
select DB_TYPE in "${DB_VERSIONS[@]}"; do
    if [ -n "$DB_TYPE" ]; then
        break
    fi
    echo "Please select a valid option"
done

# First optional step: ACF Pro configuration
echo -e "\n${BOLD}ACF Pro Configuration (press Enter to skip)${NC}"
read -p "ACF Pro license key: " ACF_KEY
read -p "ACF Pro associated domain: " ACF_DOMAIN

# Second optional step: Borlabs Cookie configuration
echo -e "\n${BOLD}Borlabs Cookie Configuration (press Enter to skip)${NC}"
read -p "Borlabs Cookie license key: " BORLABS_KEY

# Start replacement process
print_step "Setting up project structure..."

# 1. DDEV Configuration
print_step "Configuring DDEV..."
if [ -f .ddev/config.yaml ]; then
    if ! check_file_exists ".ddev/config.yaml"; then
        print_step "Skipping DDEV configuration..."
    else
        sed -i.bak "s/__your-project-name__/$PROJECT_NAME/g" .ddev/config.yaml
        sed -i.bak "s/php_version: \".*\"/php_version: \"$PHP_VERSION\"/g" .ddev/config.yaml
        sed -i.bak "s/mariadb:.*\|mysql:.*/$DB_TYPE/g" .ddev/config.yaml
        rm .ddev/config.yaml.bak
    fi
fi

# 2. Environment Setup
print_step "Setting up environment..."
if [ -f .env.example ] && ! [ -f .env ]; then
    cp .env.example .env
    DDEV_URL="$PROJECT_NAME.ddev.site"

    # Replace database credentials
    sed -i.bak 's/^DB_NAME=.*/DB_NAME=db/' .env
    sed -i.bak 's/^DB_USER=.*/DB_USER=db/' .env
    sed -i.bak 's/^DB_PASSWORD=.*/DB_PASSWORD=db/' .env
    sed -i.bak 's/^DB_HOST=.*/DB_HOST=db/' .env

    # Set WordPress Protocol and Domain
    sed -i.bak "s|^WP_PROTOCOL=.*|WP_PROTOCOL='https://'|" .env
    sed -i.bak "s|^WP_DOMAIN=.*|WP_DOMAIN='$DDEV_URL'|" .env

    # Set WordPress URLs
    sed -i.bak 's|^WP_HOME=.*|WP_HOME="${WP_PROTOCOL}${WP_DOMAIN}"|' .env
    sed -i.bak 's|^WP_SITEURL=.*|WP_SITEURL="${WP_HOME}/wp"|' .env

    # Generate and set WordPress salts
    for salt in AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT; do
        GENERATED_SALT=$(generate_salt)
        # Escape special characters in the generated salt
        ESCAPED_SALT=$(echo "$GENERATED_SALT" | sed 's/[\/&]/\\&/g')
        sed -i.bak "s/^$salt=.*/$salt='$ESCAPED_SALT'/" .env
    done

    rm .env.bak
elif [ -f .env ]; then
    print_warning ".env file already exists, skipping environment setup"
fi

# 3. Theme Setup
print_step "Setting up theme..."
OLD_THEME_PATH="packages/themes/__your-main-theme__"
NEW_THEME_PATH="packages/themes/$THEME_NAME"

if [ -d "$OLD_THEME_PATH" ]; then
    if [ -d "$NEW_THEME_PATH" ]; then
        if ! check_file_exists "$NEW_THEME_PATH"; then
            print_step "Skipping theme setup..."
        else
            rm -rf "$NEW_THEME_PATH"
            mv "$OLD_THEME_PATH" "$NEW_THEME_PATH"
        fi
    else
        mv "$OLD_THEME_PATH" "$NEW_THEME_PATH"
    fi

    # Update theme files using the correct placeholder format
    find "$NEW_THEME_PATH" -type f -exec sed -i.bak "s/__your-vendor__/$VENDOR_NAME/g" {} \;
    find "$NEW_THEME_PATH" -type f -exec sed -i.bak "s/__your-main-theme__/$THEME_NAME/g" {} \;
    find "$NEW_THEME_PATH" -name "*.bak" -type f -delete
fi

# 4. Composer Setup
print_step "Setting up Composer..."
if [ -f composer.json ]; then
    if ! check_file_exists "composer.json"; then
        print_step "Skipping Composer setup..."
    else
        sed -i.bak "s/__your-vendor__/$VENDOR_NAME/g" composer.json
        sed -i.bak "s/__your-project-name__/$PROJECT_NAME/g" composer.json
        sed -i.bak "s/__your-main-theme__/$THEME_NAME/g" composer.json
        rm composer.json.bak
    fi
fi

# Set up auth.json if any credentials were provided
if [ -f auth.json.example ] && ! [ -f auth.json ]; then
    cp auth.json.example auth.json

    # Initialize the auth.json with an empty JSON object
    echo "{}" > auth.json

    # Add ACF configuration if credentials were provided
    if [ -n "$ACF_KEY" ] && [ -n "$ACF_DOMAIN" ]; then
        print_step "Adding ACF Pro credentials..."
        sed -i.bak "s/{/{\n  \"advanced-custom-fields.composer.login\": {\n    \"username\": \"$ACF_KEY\",\n    \"password\": \"$ACF_DOMAIN\"\n  }/g" auth.json
    fi

    # Add Borlabs configuration if key was provided
    if [ -n "$BORLABS_KEY" ]; then
        print_step "Adding Borlabs Cookie credentials..."
        if [ -n "$ACF_KEY" ] && [ -n "$ACF_DOMAIN" ]; then
            # If ACF was added, we need a comma
            sed -i.bak "s/  }/  },\n  \"borlabs-cookie.composer.borlabs.io\": {\n    \"username\": \"irrelevant\",\n    \"password\": \"$BORLABS_KEY\"\n  }/g" auth.json
        else
            # If no ACF, just add Borlabs
            sed -i.bak "s/{}/{  \"borlabs-cookie.composer.borlabs.io\": {\n    \"username\": \"irrelevant\",\n    \"password\": \"$BORLABS_KEY\"\n  }}/g" auth.json
        fi
    fi

    rm auth.json.bak
elif [ -f auth.json ]; then
    print_warning "auth.json already exists, skipping authentication configuration"
fi

# Optional deployment configuration prompt
read -p "Would you like to configure deployment settings? (y/N) " configure_deployment
if [[ $configure_deployment =~ ^[Yy]$ ]]; then
    # Staging configuration
    if [ -f ".gitlab/config/staging.yml" ]; then
        echo -e "\n${BOLD}Configuring Staging Deployment${NC}"
        read -p "Staging Gitlab Deploy key variable (base64): " STAGING_DEPLOY_KEY
        read -p "Staging Deploy user: " STAGING_DEPLOY_USER
        read -p "Staging Deploy server: " STAGING_DEPLOY_SERVER
        read -p "Staging Deploy path: " STAGING_DEPLOY_PATH
        read -p "PHP binary path (default: /usr/bin/php): " STAGING_PHP_BINARY
        STAGING_PHP_BINARY=${STAGING_PHP_BINARY:-/usr/bin/php}

        if check_file_exists ".gitlab/config/staging.yml"; then
            # Replace values
            sed -i.bak "s/__NAME_OF_GITLAB_DEPLOY_KEY_VARIABLE_-_BASE64ENCODED_SSH_PRIVATE_KEY/$STAGING_DEPLOY_KEY/g" ".gitlab/config/staging.yml"
            sed -i.bak "s/__enter-your-ssh-user-here__/$STAGING_DEPLOY_USER/g" ".gitlab/config/staging.yml"
            sed -i.bak "s/__enter-remote-ssh-server-here__/$STAGING_DEPLOY_SERVER/g" ".gitlab/config/staging.yml"
            sed -i.bak "s/__enter\/deployment\/path\/on\/remote\/server__/$STAGING_DEPLOY_PATH/g" ".gitlab/config/staging.yml"
            sed -i.bak "s/__enter-php-binary-path-like-usr\/bin\/php__/$STAGING_PHP_BINARY/g" ".gitlab/config/staging.yml"

            # Remove comments
            sed -i.bak 's/^[[:space:]]*#DEPLOY/    DEPLOY/g' ".gitlab/config/staging.yml"
            sed -i.bak 's/^[[:space:]]*#PHP/    PHP/g' ".gitlab/config/staging.yml"
            sed -i.bak 's/^[[:space:]]*#KEEP/    KEEP/g' ".gitlab/config/staging.yml"

            rm ".gitlab/config/staging.yml.bak"
        fi
    fi

    # Production configuration
    if [ -f ".gitlab/config/production.yml" ]; then
        echo -e "\n${BOLD}Configuring Production Deployment${NC}"
        read -p "Production Gitlab Deploy key variable (base64): " PROD_DEPLOY_KEY
        read -p "Production Deploy user: " PROD_DEPLOY_USER
        read -p "Production Deploy server: " PROD_DEPLOY_SERVER
        read -p "Production Deploy path: " PROD_DEPLOY_PATH
        read -p "PHP binary path (default: /usr/bin/php): " PROD_PHP_BINARY
        PROD_PHP_BINARY=${PROD_PHP_BINARY:-/usr/bin/php}

        if check_file_exists ".gitlab/config/production.yml"; then
            # Replace values
            sed -i.bak "s/__NAME_OF_GITLAB_DEPLOY_KEY_VARIABLE_-_BASE64ENCODED_SSH_PRIVATE_KEY/$PROD_DEPLOY_KEY/g" ".gitlab/config/production.yml"
            sed -i.bak "s/__enter-your-ssh-user-here__/$PROD_DEPLOY_USER/g" ".gitlab/config/production.yml"
            sed -i.bak "s/__enter-remote-ssh-server-here__/$PROD_DEPLOY_SERVER/g" ".gitlab/config/production.yml"
            sed -i.bak "s/__enter\/deployment\/path\/on\/remote\/server__/$PROD_DEPLOY_PATH/g" ".gitlab/config/production.yml"
            sed -i.bak "s/__enter-php-binary-path-like-usr\/bin\/php__/$PROD_PHP_BINARY/g" ".gitlab/config/production.yml"

            # Remove comments
            sed -i.bak 's/^[[:space:]]*#DEPLOY/    DEPLOY/g' ".gitlab/config/production.yml"
            sed -i.bak 's/^[[:space:]]*#PHP/    PHP/g' ".gitlab/config/production.yml"
            sed -i.bak 's/^[[:space:]]*#KEEP/    KEEP/g' ".gitlab/config/production.yml"

            rm ".gitlab/config/production.yml.bak"
        fi
    fi
fi

print_step "Configuration complete!"
echo -e "\nTo initialize your project with ddev, run these commands:"
echo "ddev start"
echo "ddev composer install"
echo "ddev exec 'npm install && npm run build'"
echo -e "After ddev setup, you can access your site at: https://$PROJECT_NAME.ddev.site"
print_success "\nSetup complete! 🎉"