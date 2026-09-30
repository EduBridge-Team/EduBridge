# Web styles

Keep styles with their owner instead of adding page-specific overrides to global files.

| Owner | Location | Responsibility |
| --- | --- | --- |
| Shared theme | `theme/tokens.css`, `theme/portal-tokens.css` | Global and portal light/dark tokens |
| Header | `components/topbar.css` | Entry point for base, guest navigation, and shared dimensions |
| Footer | `components/footer.css` | Footer layout, colors, links, and responsive rules |
| Authentication | `auth/` | Forms, split layout, artwork, and interaction refinements |
| Homepage | `homepage/` | Hero and public sections |
| Role portal | `role-portal/` | Portal layout and role/page surfaces |
| Global primitives | `global/` | Shared controls and compatibility import entry points |
| Brand identity | `identity/` | Brand presentation and existing shared refinements |

`main.jsx` loads theme tokens before the existing base styles. Dark refinements and
`identity/shared-shell.css` load last. The latter imports the shared header/footer.
The compatibility entry files retain the order of existing page rules.

Header height and logo dimensions use `--site-header-*` tokens. Adjust them in the
header styles, including the mobile breakpoint, rather than adding local sizes.
Portal placement rules remain in the portal because they decide when its toolbar
replaces the public header.

Use global tokens for shared colors and component-scoped tokens for local palettes.
Keep media queries with their component. Check asset references across the repository
before removing public files; the homepage fallback and About image are intentional.

After a structural change, run `npm run build`, `npm run lint`, and
`node --test tests/*.test.mjs` from `edubridge-web`.

`styles/routes.css` eagerly loads shared page CSS in a fixed order. Route components
use `React.lazy` in `AppRoutes.jsx`; keep shared CSS here when adding a lazy route
to prevent navigation order from changing the cascade. The homepage remains eager
so section links can find their targets immediately.
