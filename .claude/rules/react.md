---
paths:
  - "**/*.jsx"
  - "**/*.tsx"
  - "**/hooks/**"
---

# React

For React components and hooks. It builds on `code-style.md`. Inside a
WordPress project `wordpress-frontend.md` wins, and for Next.js routing,
data fetching and Server Actions the `nextjs-developer` skill has the
details. React Native follows this file too, minus anything about the DOM.
Hooks in plain `.ts` or `.js` files outside a `hooks/` folder don't load
this file on their own, so read it yourself when `package.json` lists
`react`.

## Version and setup

- Read the React version from `package.json` and the lockfile. React 19
  features (`use()`, `useActionState`, `ref` as a plain prop, form actions)
  only go in projects on 19.
- If the project uses React Compiler, leave out `useMemo`, `useCallback`
  and `memo` unless profiling shows they still help.
- Match the project's styling (Tailwind, CSS modules, styled-components) and
  state libraries. Don't add a new one without asking.

## Formatting

Prettier formats everything, as `formatting.md` describes. With no project
config that means `~/.prettierrc`: 2 spaces, single quotes, no semicolons,
ES5 trailing commas, 80 columns.

## Components

- Function components only. A class component stays a class unless the task
  is to convert it.
- `PascalCase` names, and the file name matches the main component unless
  the project names files another way. One exported component per file.
- Type props with a `type` or `interface` named `<Component>Props`, and
  destructure them in the signature. No `React.FC`.
- Render stays pure: no fetching, subscriptions or mutation while
  rendering.
- Props for callbacks are named `onX`, the handlers that implement them
  `handleX`.
- Keys are stable IDs from the data. Use the index only for a list that
  never reorders, filters or inserts.
- No inline style objects except for values computed at runtime.

## State

- Keep state as local as it can be, and lift it only as far as the nearest
  component that needs it.
- Derive what you can during render. Never copy props into state, and never
  use an effect to keep one piece of state in step with another.
- Context for values that change rarely (theme, current user). Frequently
  changing shared state goes in the store the project already uses.
- Server data goes through the project's data layer (TanStack Query, SWR,
  framework loaders) instead of hand-rolled `useEffect` fetching.

## Effects and hooks

- An effect is for syncing with something outside React: a subscription, a
  timer, a DOM API, a non-React widget. If nothing external is involved, you
  don't need one.
- Every effect that subscribes, listens or starts a timer returns a cleanup.
  A fetch in an effect uses an `AbortController`.
- Dependency arrays are complete. Never disable `react-hooks/exhaustive-deps`;
  fix the dependency instead.
- Follow the rules of hooks: top level only, never in a condition or loop.
- Custom hooks start with `use` and live in `hooks/` or beside the component
  that owns them.

## Performance

Measure before optimizing. `lazy()` and `Suspense` for route-level code
splitting, virtualization for lists in the hundreds, and memoization only
where the profiler points.

## Security

- No `dangerouslySetInnerHTML` with anything a user could have touched
  unless it's been through DOMPurify or the project's sanitizer.
- Check URLs from data before putting them in `href` or `src`. A
  `javascript:` link runs code.
- Anything prefixed `NEXT_PUBLIC_`, `VITE_` or `REACT_APP_` ships to the
  browser. Secrets never get those prefixes.

## Accessibility

- Semantic elements first: `<button>` for actions, never a `div` with
  `onClick`. Headings in order.
- Every input has a label. Every image has `alt`, empty for decorative ones.
- Everything works from the keyboard. Modals trap focus and give it back on
  close.
- Lint with `eslint-plugin-jsx-a11y` when the project has it.

## Tests

- React Testing Library, querying by role and label the way a user would.
  `userEvent` over `fireEvent`.
- Test behavior, not implementation: no assertions on state or internal
  calls.
- Mock the network at the boundary (MSW when the project has it), not the
  component's own modules.

## Before finishing

Run what the project has: `tsc --noEmit`, ESLint, Prettier in check mode,
and the tests that cover the change. Say which ones it doesn't have.
