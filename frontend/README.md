# Nincsenek Fények! - Frontend

Modern React + TypeScript + Vite frontend a Nincsenek Fények! tényellenőrző platformhoz.

## Tech Stack

- **React 18** - UI library
- **TypeScript** - Type safety
- **Vite** - Build tool
- **Tailwind CSS** - Styling
- **React Router** - Routing
- **TanStack Query** - Data fetching
- **Axios** - HTTP client
- **Lucide React** - Icons

## Telepítés

```bash
cd frontend
npm install
```

## Fejlesztés

```bash
npm run dev
```

A frontend elérhető lesz: http://localhost:5173

## Build

```bash
npm run build
```

A build output a `dist/` mappába kerül.

## Docker

A frontend Docker konténerben is futtatható. Nézd meg a `Dockerfile` fájlt.

## Környezeti Változók

Hozz létre egy `.env` fájlt:

```env
VITE_API_URL=http://localhost:8095/api
```

## Projekt Struktúra

```
frontend/
├── src/
│   ├── components/     # Reusable components
│   ├── pages/          # Page components
│   ├── lib/            # Utilities and API client
│   └── App.tsx         # Main app component
├── public/             # Static assets
└── package.json
```

