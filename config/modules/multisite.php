<?php

use Roots\WPConfig\Config;
use function Env\env;

/**
* Multisite enable
*/

/**
* initialization: uncomment the following line
*/
//Config::define('WP_ALLOW_MULTISITE', true);

/**
* multisite enabled and set up via database
*/
Config::define('MULTISITE', true);
Config::define('SUBDOMAIN_INSTALL', true);
Config::define('DOMAIN_CURRENT_SITE', env('WP_DOMAIN'));
Config::define('PATH_CURRENT_SITE', '/');
Config::define('SITE_ID_CURRENT_SITE', 1);
Config::define('BLOG_ID_CURRENT_SITE', 1);

/**
* Use WP_DOMAIN (=~DOMAIN_CURRENT_SITE) as the cookie domain. This ensures cookies and
* nonces are using the correct domain for the corresponding site. Without
* this, logins, REST requests, Gutenberg AJAX requests, and other actions
* which require verification will not work.
*
* source: https://discourse.roots.io/t/woocommerce-rest-api-multisite-issues-401-403/21276
*/

Config::define('ADMIN_COOKIE_PATH', '/');
Config::define('COOKIE_DOMAIN', '');
Config::define('COOKIEPATH', '/');
Config::define('SITECOOKIEPATH', '/');