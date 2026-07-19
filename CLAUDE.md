# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

This is **Meet2Discuss Admin Dashboard** — a Flutter web app that gives admins a read-only analytics view over a Supabase (Postgres) backend for the Meet2Discuss product (members, opportunities, conversations, messages, etc.). It talks directly to Supabase from the client; there is no custom backend server in this repo. It is deployed as a static web build to Firebase Hosting.

## Commands

```bash
flutter pub get                 # install dependencies
flutter run -d chrome           # run the app (this is a web-first app)
flutter analyze                 # static analysis (flutter_lints via analysis_options.yaml)
flutter test                    # run tests
flutter test test/widget_test.dart   # run a single test file
flutter build web                # production web build -> build/web
firebase deploy                  # deploy build/web to Firebase Hosting (project: analytics-meet2discuss)
```

There is no CI config, formatter script, or custom lint config beyond the default `flutter_lints` ruleset in `analysis_options.yaml`.

**Note:** `test/widget_test.dart` is still the unmodified `flutter create` boilerplate (a counter smoke test). It does not exercise this app's actual widget tree (`MyApp` now renders the router/dashboard, not a counter) and will fail if run. Treat it as a placeholder to replace, not a passing baseline.

## Architecture

### Feature-first structure under `lib/`

- `core/` — cross-cutting app config: `constants.dart` (colors + Supabase URL/anon key), `supabase_config.dart` (Supabase client init), `routes.dart` (`go_router` setup).
- `auth/` — login UI, `AuthService` (Supabase auth calls), `AuthCubit`/`AuthState`.
- `dashboard/` — the main (only) authenticated screen: `AnalyticsService` (all Supabase data-fetching), `DashboardCubit`/`DashboardState`, `DashboardPage`.
- `models/` — plain data classes (`DashboardStats` and friends) shared between the service and UI layers.
- `widgets/` — reusable presentational widgets (`StatCard`, `GrowthChart`, and the `RecentUsersTable`/`RecentOpportunitiesTable`/`RecentConversationsTable` trio).

### State management pattern

Uses `flutter_bloc` **Cubits** (not full Bloc event/state classes) — each Cubit exposes plain async methods (`loginWithEmail`, `loadDashboard`, `sortUsers`, ...) that `emit` new states directly. Both cubits are provided app-wide via `MultiBlocProvider` in `main.dart`.

### Auth flow and route guarding

`AuthCubit` doesn't just track Supabase session state — it layers an app-specific admin gate on top:

1. `AuthService.onAuthStateChange` fires on Supabase sign-in/out.
2. On sign-in, `AuthCubit._verifyAdmin` calls `AuthService.getAdminUserRole`, which looks up the user in the `admin_users` table (checks `is_active` and reads `role_id`).
3. Only if that lookup succeeds does the cubit emit `Authenticated`; otherwise it emits `AccessDenied` (a signed-in Supabase user who isn't an active admin — shown a distinct "Access Denied" screen with a logout button, not bounced straight back to the login form).

`AppRouter` (`core/routes.dart`) drives redirects off `AuthCubit`'s state via a `ChangeNotifier` wrapping its stream, so navigation reacts live to auth/verification changes. Routes are just `/login` and `/dashboard` — there is no other authenticated screen.

### Dashboard data flow

`AnalyticsService.fetchDashboardStats()` is the single entry point that assembles one `DashboardStats` object by querying Supabase tables in parallel (`profiles`, `opportunities`, `participants`, `conversations`, `messages`, `notifications`, `saved_opportunities`, `blocked_users`, `user_reports`, `conversation_members`), plus per-table recent-rows queries and a 6-month growth breakdown per entity (`_buildRealGrowth`). `DashboardCubit.loadDashboard()` calls this once and emits `DashboardLoaded`/`DashboardError`; `sortUsers()` re-sorts the already-fetched `recentUsers` client-side (no re-fetch) by rebuilding `DashboardStats` with a new `recentUsers` list.

Individual queries fail independently (each wrapped in try/catch, defaulting to 0 / empty list) so one missing/renamed table doesn't take down the whole dashboard.

**Schema gotchas already discovered and documented in `analytics_service.dart` — check there before changing queries:**
- `profiles` has no `email` column; email only lives in Supabase's `auth.users`. City is shown in the recent-users table instead.
- `opportunities` has no `created_by` column — the host FK is `host_id`, joined to `profiles` as `host:profiles!host_id(name)`, with a fallback query (no join) if that join fails.
- Growth charts never fabricate data — a failed query returns explicit zero-valued points for each of the last 6 months rather than sample/fake data.

### UI conventions

- Dark theme only (`ThemeMode.dark`, forced in `main.dart`); color palette is centralized in `AppColors` (`core/constants.dart`) — don't hardcode colors in widgets.
- Fonts via `google_fonts`: `GoogleFonts.outfit` for headings/titles, `GoogleFonts.inter` for body/labels.
- Responsive breakpoints are ad hoc `MediaQuery` width checks repeated per-widget (mobile ≤700, tablet 700–1100, desktop >1100) rather than a shared responsive utility — follow the existing pattern in `dashboard_page.dart` if adding new breakpoint-aware sections.
- Charts use `fl_chart`; tables use Flutter's `DataTable` wrapped in a shared internal `_Card` style.

### Known repo quirks

- Supabase URL and anon (publishable) key are hardcoded in `lib/core/constants.dart` rather than loaded from environment/`--dart-define`. The anon key is a public/publishable key by design, not a secret, but this is the file to edit when pointing at a different Supabase project.
- If Supabase initialization throws, `main.dart` only logs a "Running in Demo Mode" message to the console — there is no actual demo-mode data path; the app will otherwise proceed with an uninitialized client.
- `yes/index.html` at the repo root is a leftover default Firebase Hosting welcome page (from `firebase init hosting`, predating any `flutter build web` output) — it is not part of the app and is unrelated to `web/index.html`, which is the real Flutter web entrypoint.
