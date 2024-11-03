<?php
/**
 * Configuration overrides for WP_ENV === 'staging'
 */

use Roots\WPConfig\Config;

/**
 * You should try to keep staging as close to production as possible. However,
 * should you need to, you can always override production configuration values
 * with `Config::define`.
 *
 * Example: `Config::define('WP_DEBUG', true);`
 * Example: `Config::define('DISALLOW_FILE_MODS', false);`
 */

/* set WP_ENVIRONMENT_TYPE as well to support some plugins */
Config::define('WP_ENVIRONMENT_TYPE ', 'production');

Config::define('WP_DEBUG', false);
Config::define('DISALLOW_INDEXING', false);
