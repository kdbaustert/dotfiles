// The fallback ESLint config for any file under $HOME whose project has none.
// link_dotfiles() links it to ~/eslint.config.mjs. ESLint 10 looks for a config
// walking up from each linted file's directory, so the nearest project config
// always wins and this one is only reached when nothing closer exists.
//
// It lives here rather than as a root-level dotfile because its imports
// resolve from the real path of this file, which is this directory's
// node_modules. A pnpm -g copy of these packages can't be imported: each
// global gets its own isolated directory, the same wall .prettierrc hit with
// its PHP plugin. setup/pnpm.sh installs the dependencies here.
//
// Where it breaks: a project still on .eslintrc lints with this file instead
// of its own. ESLint 8 switches to flat config as soon as it finds one walking
// up from the current directory; set ESLINT_USE_FLAT_CONFIG=false in that
// project. ESLint 9 used to stop with "couldn't find eslint.config" there and
// now runs these rules instead, so the project needs its own flat config or
// that same variable.
import js from '@eslint/js'
import vue from 'eslint-plugin-vue'
import prettier from 'eslint-config-prettier'
import globals from 'globals'
import tseslint from 'typescript-eslint'

export default [
  {
    // Build output and third-party code in projects that don't have a config
    // to say so. node_modules and .git are ignored by ESLint already.
    ignores: ['**/dist/', '**/build/', '**/vendor/', '**/*.min.js'],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  ...vue.configs['flat/recommended'],
  {
    // <script lang="ts"> blocks need the TypeScript parser, which
    // eslint-plugin-vue takes as a nested parser option.
    files: ['**/*.vue'],
    languageOptions: { parserOptions: { parser: tseslint.parser } },
  },
  {
    // A stray file could be a browser script or a Node one, and there's no
    // project to say which, so both sets of globals are defined.
    languageOptions: {
      globals: { ...globals.browser, ...globals.node },
    },
  },
  // Last, so it turns off every layout rule above. Prettier owns formatting.
  prettier,
]
