# TeleTech web console

React console for system admins, company admins, and drivers admins. It talks only to the Laravel API in `/backend`. Drivers and employees are rejected at login and stay on the mobile app.

## Setup

```bash
cd web
npm install
cp .env.example .env
npm run dev
```

On Windows PowerShell, copy the env file with `Copy-Item .env.example .env`.

The dev server is `http://localhost:5173`. The API base URL defaults to `http://127.0.0.1:8000/api` (`VITE_API_BASE_URL`). Start the Laravel API first (`php artisan serve --host=0.0.0.0 --port=8000` from `/backend`).

The browser token is stored in `localStorage`. A 401 clears it and returns to `/login`. A 403 with `code: password_change_required` opens `/change-password`.

## Scripts

| Script              | What it does                              |
| ------------------- | ----------------------------------------- |
| `npm run dev`       | Vite on port 5173                         |
| `npm run build`     | Typecheck and production build            |
| `npm run preview`   | Preview the production build on port 5173 |
| `npm run lint`      | ESLint                                    |
| `npm run test`      | Vitest                                    |
| `npm run typecheck` | `tsc -b --noEmit`                         |

## Roles

After login the app opens `/admin`, `/company-admin`, or `/drivers-admin`. Language (English / Arabic) is stored locally and sets `dir` on the document, so the sidebar and spacing flip for Arabic.

The API contract is in [docs/API.md](docs/API.md).
