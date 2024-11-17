#!/bin/bash

# Function to parse nested YAML using awk
parse_yaml() {
    local environment=$2
    local config_key=".${environment}_config"
    awk -v env="$config_key" '
    BEGIN { in_config = 0; in_variables = 0; }
    $0 ~ "^"env":" { in_config = 1; next }
    in_config && /^[[:space:]]*variables:/ { in_variables = 1; next }
    in_config && /^[^[:space:]]/ { in_config = 0; in_variables = 0 }
    in_variables && /^[[:space:]]+[A-Z_]+:/ {
        key = $1
        gsub(/:/, "", key)
        value = $2
        # Concatenate remaining fields for values with spaces
        for (i=3; i<=NF; i++) value = value " " $i
        # Remove quotes and leading/trailing spaces
        gsub(/^[[:space:]"'\'']*|[[:space:]"'\'']*$/, "", value)
        if (length(key) > 0 && length(value) > 0) {
            print key "=" value
        }
    }
    ' "$1"
}

# Function to validate required variables
validate_required_vars() {
    local config_file=$1
    local environment=$2
    local missing_vars=()

    # Parse and evaluate YAML content
    echo "Parsing configuration for ${environment}_config..."
    local parsed_output=$(parse_yaml "$config_file" "$environment")
    echo "Debug - Parsed output:"
    echo "$parsed_output"

    # Use a subshell to avoid polluting the environment
    eval "$parsed_output"

    # Check each required variable
    [[ -z "$DEPLOY_USER" ]] && missing_vars+=("DEPLOY_USER")
    [[ -z "$DEPLOY_SERVER" ]] && missing_vars+=("DEPLOY_SERVER")
    [[ -z "$DEPLOY_PATH" ]] && missing_vars+=("DEPLOY_PATH")

    # If any variables are missing, print error and exit
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "Error: Required variables not found in ${environment}_config variables section of $config_file"
        echo "The following variables must be present and not commented out:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo
        echo "Expected YAML structure:"
        echo ".${environment}_config:"
        echo "  extends: .wp_defaults"
        echo "  variables:"
        echo "    DEPLOY_USER: \"your-user\""
        echo "    DEPLOY_SERVER: \"your-server\""
        echo "    DEPLOY_PATH: \"/path/to/deployment\""
        exit 1
    fi

    echo "✓ Required variables found:"
    echo "  - DEPLOY_USER: $DEPLOY_USER"
    echo "  - DEPLOY_SERVER: $DEPLOY_SERVER"
    echo "  - DEPLOY_PATH: $DEPLOY_PATH"
}

# Function to get user confirmation
confirm_execution() {
    local environment=$1

    echo "=============================================="
    echo "🚨 Please review the deployment configuration 🚨"
    echo "=============================================="
    echo "Environment: $environment"
    echo "Server: $DEPLOY_SERVER"
    echo "User: $DEPLOY_USER"
    echo "Path: $DEPLOY_PATH"
    echo "=============================================="
    echo "This script will:"
    echo "1. Create directory structure if not exists:"
    echo "   - $DEPLOY_PATH/cache"
    echo "   - $DEPLOY_PATH/releases"
    echo "   - $DEPLOY_PATH/shared"
    echo "   - $DEPLOY_PATH/shared/web"
    echo "   - $DEPLOY_PATH/shared/web/app"
    echo "   - $DEPLOY_PATH/shared/web/app/languages"
    echo "   - $DEPLOY_PATH/shared/web/app/uploads"
    echo "2. Create .env file if not exists at:"
    echo "   - $DEPLOY_PATH/shared/web/.env"
    echo "3. Set appropriate permissions (755 for dirs, 644 for files)"
    echo "=============================================="

    while true; do
        read -p "Do you want to proceed with this configuration? [y/N] " yn
        case $yn in
            [Yy]* )
                echo "Proceeding with deployment setup..."
                return 0
                ;;
            [Nn]* | "" )
                echo "Deployment setup cancelled by user"
                exit 1
                ;;
            * )
                echo "Please answer 'y' (yes) or 'n' (no)"
                ;;
        esac
    done
}

# Function to check if remote path exists
check_remote_path() {
    local ssh_command="ssh $DEPLOY_USER@$DEPLOY_SERVER"
    local path="$1"
    if $ssh_command "[ -e \"$path\" ]"; then
        return 0 # Path exists
    else
        return 1 # Path doesn't exist
    fi
}

# Function to create directory with checks
create_remote_directory() {
    local ssh_command="ssh $DEPLOY_USER@$DEPLOY_SERVER"
    local path="$1"
    local dir_name="$(basename "$path")"

    if check_remote_path "$path"; then
        echo "✓ Directory '$dir_name' already exists at: $path"
    else
        echo "Creating directory: $path"
        if $ssh_command "mkdir -p \"$path\""; then
            echo "✓ Successfully created directory: $dir_name"
        else
            echo "✗ Failed to create directory: $path"
            return 1
        fi
    fi
    return 0
}

# Function to create the remote directory structure and .env file
create_remote_structure() {
    local ssh_command="ssh $DEPLOY_USER@$DEPLOY_SERVER"

    echo "=== Starting Remote Directory Structure Setup ==="
    echo "Target server: $DEPLOY_SERVER"
    echo "Deploy user: $DEPLOY_USER"
    echo "Deploy path: $DEPLOY_PATH"
    echo "Environment: $environment"
    echo "================================================"

    # Array of directories to create
    local directories=(
        "$DEPLOY_PATH"
        "$DEPLOY_PATH/cache"
        "$DEPLOY_PATH/releases"
        "$DEPLOY_PATH/shared"
        "$DEPLOY_PATH/shared/web"
        "$DEPLOY_PATH/shared/web/app"
        "$DEPLOY_PATH/shared/web/app/languages"
        "$DEPLOY_PATH/shared/web/app/uploads"
    )

    # Create each directory with checks
    local failed=0
    for dir in "${directories[@]}"; do
        if ! create_remote_directory "$dir"; then
            failed=1
            echo "✗ Error occurred while creating directory structure"
            return 1
        fi
    done

    # Check and create .env file
    local env_path="$DEPLOY_PATH/shared/web/.env"
    if check_remote_path "$env_path"; then
        echo "! .env file already exists. Skipping creation to prevent overwriting existing configuration."
        echo "  Location: $env_path"
    else
        echo "Creating .env file..."
        $ssh_command "cat > $env_path" << EOL
DB_NAME=''
DB_USER=''
DB_PASSWORD=''
DB_HOST=''

# Optionally, you can use a data source name (DSN)
# When using a DSN, you can remove the DB_NAME, DB_USER, DB_PASSWORD, and DB_HOST variables
# DATABASE_URL='mysql://database_user:database_password@database_host:database_port/database_name'

# Optional database variables
# DB_PREFIX='wp_'

WP_ENV='${environment}'

# WP_PROTOCOL and WP_DOMAIN are not actually used by Wordpress but make it easier to piece together our domain configuration
WP_PROTOCOL='https://'
WP_DOMAIN=''

WP_HOME="\${WP_PROTOCOL}\${WP_DOMAIN}"
WP_SITEURL="\${WP_PROTOCOL}\${WP_DOMAIN}/wp" # the wordpress admin url, in segment "wp" in bedrock projects

# Specify optional debug.log path
# WP_DEBUG_LOG='/path/to/debug.log'

# Generate your keys here: https://roots.io/salts.html
AUTH_KEY=
SECURE_AUTH_KEY=
LOGGED_IN_KEY=
NONCE_KEY=
AUTH_SALT=
SECURE_AUTH_SALT=
LOGGED_IN_SALT=
NONCE_SALT=

# vite options
VITE_USE_DEV_SERVER = 'false'
VITE_DEV_SERVER_URI = 'auto'
EOL
        if [ $? -eq 0 ]; then
            echo "✓ Successfully created .env file"
            # Set appropriate permissions
            $ssh_command "chmod 644 \"$env_path\""
            if [ $? -eq 0 ]; then
                echo "✓ Set permissions on .env file (644)"
            else
                echo "✗ Failed to set permissions on .env file"
                return 1
            fi
        else
            echo "✗ Failed to create .env file"
            return 1
        fi
    fi

    # Set directory permissions
    echo "Setting directory permissions..."
    if $ssh_command "find \"$DEPLOY_PATH\" -type d -exec chmod 755 {} \;"; then
        echo "✓ Successfully set directory permissions (755)"
    else
        echo "✗ Failed to set directory permissions"
        return 1
    fi

    echo "================================================"
    if [ $failed -eq 0 ]; then
        echo "✓ Remote setup completed successfully!"
    else
        echo "✗ Remote setup completed with errors"
    fi
    echo "================================================"
}

# Main script
main() {
    # Check if environment argument is provided
    if [ $# -ne 1 ]; then
        echo "Usage: $0 <environment>"
        echo "Supported environments: staging, production"
        exit 1
    fi

    environment=$1
    config_file=".gitlab/config/${environment}.yml"

    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        echo "Error: Configuration file $config_file not found!"
        exit 1
    fi

    # Validate required variables with proper structure
    validate_required_vars "$config_file" "$environment"

    # Get user confirmation before proceeding
    confirm_execution "$environment"

    # Create remote structure
    create_remote_structure
}

# Execute main function with environment argument
main "$@"