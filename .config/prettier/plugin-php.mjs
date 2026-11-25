// The PHP plugin for ~/.prettierrc, loaded by path from its "plugins" entry.
//
// Prettier 3 looks up a bare plugin name ("@prettier/plugin-php") from the
// current directory only, so the global config failed on every file, JS
// included, in any project that doesn't install the plugin itself. A pnpm -g
// copy doesn't help: each global package gets its own isolated directory
// that nothing else can import from. A name starting with "." is resolved
// next to the config file instead, which is $HOME for the ~/.prettierrc link
// and the repo root for the real file. Both reach this directory, through the
// ~/.config/prettier link or directly.
//
// A file of our own rather than a path into node_modules, so the entry point
// comes from the plugin's package exports and a release that moves its source
// can't break the config. setup/pnpm.sh installs the dependencies here.
export * from '@prettier/plugin-php'
