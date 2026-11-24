---
paths:
  - "**/*.vue"
  - "**/composables/**"
  - "**/stores/**"
  - "**/nuxt.config.*"
---

# Vue

For Vue 3 apps and components. It builds on `code-style.md`, and where it
disagrees with the `vue-expert` or `vue-expert-js` skills this file wins.
For Nuxt, the `vue-expert` skill's Nuxt reference has the details.
Composables and stores outside the `composables/` and `stores/` folders don't
load this file on their own, so read it yourself when `package.json` lists
`vue`.

## Version and setup

- Read the Vue version from `package.json` and the lockfile. `defineModel()`
  needs 3.4, reactive props destructure and `onWatcherCleanup()` need 3.5.
- TypeScript when the project uses it (`lang="ts"`), JSDoc types when it
  doesn't.
- Use the libraries already there (Pinia, VueUse, Vue Router, the UI kit).
  Don't add one without asking.

## Formatting

Prettier formats everything, as `formatting.md` describes. With no project
config that means `~/.prettierrc`: 2 spaces, single quotes, no semicolons,
ES5 trailing commas, 80 columns. Lint with `eslint-plugin-vue` at the
`recommended` level or whatever the project sets.

## Components

- New components use `<script setup>` and the Composition API. An existing
  Options API file stays that way unless the task is to convert it; don't
  mix the two in one file.
- Block order: `<script>`, `<template>`, `<style>`.
- Component names have more than one word (`TodoItem`, not `Todo`), so they
  never clash with HTML elements. `PascalCase` file names and `PascalCase`
  tags in templates.
- Base components share a prefix (`BaseButton`, `AppIcon`). A child that only
  makes sense inside one parent carries the parent's name:
  `TodoListItem`.
- Type props with `defineProps<{ ... }>()`. Defaults go through reactive
  props destructure on 3.5, `withDefaults()` before it.
- Never mutate a prop. Emit an event, or use `defineModel()` for `v-model`.
  Declare every emit with `defineEmits`, typed.
- `<style scoped>` or CSS modules. Global styles only in the app's global
  stylesheet.

## Reactivity

- `ref()` by default, for objects too. `reactive()` only where the project
  already uses it, and never destructure a `reactive()` object without
  `toRefs()`, or the parts stop being reactive.
- `computed()` for anything derived. Computed getters have no side effects.
- `watch()` and `watchEffect()` are for side effects only. If you're watching
  one value to set another, it's a `computed()`.
- Watchers and listeners started outside setup get cleaned up, with
  `onWatcherCleanup()`, `onScopeDispose()` or `onUnmounted()`.
- `shallowRef()` for large data you replace rather than change in place.
- Don't touch the DOM before `onMounted()`. Use template refs, not
  `document.querySelector()`.

## Templates

- Every `v-for` has a `:key` from the data, not the index.
- Never put `v-if` and `v-for` on the same element. Filter in a `computed()`
  or move the `v-if` to a wrapping `<template>`.
- Keep expressions short. Anything with logic moves into a `computed()` or a
  function.
- `v-html` only for HTML that's been sanitized, with a comment saying where.

## Composables and state

- Composables are named `useX`, live in `composables/`, return refs (not a
  `reactive()` object) and clean up what they start.
- Check VueUse before writing a composable when the project has it.
- Shared state goes in Pinia, as setup stores unless the project writes
  option stores. Destructure a store with `storeToRefs()`. No Vuex in new
  code.
- `provide()` and `inject()` use a typed `InjectionKey`, not a bare string.
- Routes are named and their components lazy-loaded:
  `component: () => import('./views/OrderView.vue')`.

## Security

- `v-html` and `innerHTML` need sanitized input, through DOMPurify or the
  project's sanitizer.
- Check URLs from data before binding them to `href` or `src`.
- Anything prefixed `VITE_` or `NUXT_PUBLIC_` ships to the browser. Secrets
  never get those prefixes.

## Accessibility

- `<button>` for actions, never a `div` with `@click`. Headings in order.
- Every input has a label. Every image has `alt`, empty for decorative ones.
- Everything works from the keyboard. Dialogs trap focus and give it back on
  close.
- Turn on `eslint-plugin-vuejs-accessibility` when the project has it.

## Tests

- Vitest with Vue Test Utils, or Testing Library for Vue if the project uses
  it. Query by role and label, and test what the user sees, not component
  internals.
- Mock the network at the boundary, and give stores a fresh Pinia per test
  (`createTestingPinia()` when `@pinia/testing` is installed).

## Before finishing

Run what the project has: `vue-tsc --noEmit`, ESLint, Prettier in check mode,
and the tests that cover the change. Say which ones it doesn't have.
