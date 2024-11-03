<?php

use Larsgowebdev\WPBattery\WPBattery;

$themeNamespace = '__your-main-theme__';

$wpBatteryThemeLoader = new WPBattery(
    themeNamespace: $themeNamespace,
    settings: [
        'themeSupport' => [
            'menus',
            'post-thumbnails',
        ],
        'registerBlocks' => true,
        'registerMenus' => true,
        'registerOptions' => true,
        'enableACFSync' => true,
        'allowSVGUploads' => true,
        'disallowNonACFBlocks' => true,
        'disableComments' => true,
        'enableViteAssets' => true,
        'viteBuildDir' => 'build',
        'viteEntryPoint' => 'frontend/vite.entry.js',
        'includeFrontendCSS' => [],
        'includeFrontendJS' => [],
        'includeAdminCSS' => [
            'block-preview' => [
                'path' => get_stylesheet_directory_uri() . '/assets/editor/preview.css',
            ],
        ],
        'includeAdminJS' => [],
    ]
);