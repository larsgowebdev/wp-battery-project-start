import {defineConfig, mergeConfig} from "vite";
import { dirname, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import { createRequire } from 'node:module';
const require = createRequire( import.meta.url );
import autoOrigin from "vite-plugin-auto-origin";

/*
 * universal constant configuration
 */
const ROOT_PATH = "./"
const currentDir = dirname(fileURLToPath(import.meta.url))
const rootPath = resolve(currentDir, ROOT_PATH)

const ALIASES = {
    '@Images': resolve(__dirname, 'frontend/images'),
    '@Fonts': resolve(__dirname, 'frontend/fonts'),
}

const ENTRY_POINTS = [
    "frontend/vite.entry.js",
]

const BUILD_PATH = "packages/themes/__your-main-theme__/build/"


/*
 * Set a base configuration that is used in all contexts
 * May be overridden depending on build context during defineConfig()
 */
const BASE_CONFIG= {
    base: "",
    resolve: {
        alias: ALIASES
    },
    build: {
        manifest: true,
        rollupOptions: {
            input: ENTRY_POINTS.map(entry => resolve(rootPath, entry)),
        },
        outDir: resolve(rootPath, BUILD_PATH),
    },
    css: {
        devSourcemap: true,
    },
    plugins: [
        autoOrigin(),
    ],
    publicDir: false,
}

/*
 * Define a custom file watcher in vite plugin syntax
 * Will trigger a "hot update" (without full reload) when files are changed
 */
const watchFiles = () => ({
    name: 'watch-files',
    handleHotUpdate({file, server}) {
        const watchedExtensions = [
            '.html',
            '.twig',
            '.php',
            '.scss',
            '.js',
            '.jpg',
            '.png',
            '.svg',
        ];
        if (watchedExtensions.some(ext => file.endsWith(ext))) {
            server.ws.send({
                type: 'full-reload',
                path: '*'
            });
        }
    }
})

/*
 * the actual config definition for vite.
 * Note that 'mode' is a parameter coming from cli/node (see package.json)
 */
export default defineConfig(({ mode }) => {
    switch (mode) {
        /*
         * Mode build
         * => the "classic" build for production & used in deployment
         * => includes: SCSS, JS, Assets (Images, Fonts, ...)
         * npm call: npm run build
         * vite call: vite build --mode=build
         */
        case 'build':
            return mergeConfig(BASE_CONFIG, {});

        /*
        * Mode dev
        * => used by 'ddev vite-serve' and other vite preview servers
        * => Contains a file watcher for .html, .scss, .js and common image types
        * => includes: SCSS, JS, Assets (Images, Fonts, ...)
        * ddev call: ddev vite-serve
        * npm call: npm run dev
        * vite call: vite --port 5173 --host --mode=dev
        */
        case 'dev':
        default:
            return mergeConfig(BASE_CONFIG, {
                plugins: [
                    watchFiles()
                ],
            });
    }
});
