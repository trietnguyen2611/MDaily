# MDaily – Personal Expense Tracker & Budget App (Desktop + iOS)

**MDaily** is a modern **personal expense management app** available on Desktop and iOS. Track your spending, scan receipts with OCR + AI, get smart insights, and manage your budget with a clean Apple-inspired design.

Ideal for anyone who wants a simple, beautiful, and smart way to control personal finances.

---

## Main Features

- **Expense Tracking** — Record spending, categorize expenses, add photos and notes.
- **Receipt OCR & AI** — Automatically extract amount, date, and store name from receipt images.
- **Statistics & Reports** — Clear charts and insights about your monthly spending and budget limits.
- **AI Money Assistant** — Get personalized advice on spending habits and saving tips.
- **Clean Design** — Minimal interface inspired by Apple Design System. Smooth and easy to use on both desktop and mobile.

---

## Project Structure

```text
MDaily/
├── deskapp/       # Desktop version (Electron + React + TypeScript + Vite)
├── phoneapp/      # iOS version (Capacitor + React + TypeScript + Vite)
├── DESIGN.md      # Design system rules
└── MDaily.png     # App logo
```

---

## Technologies

- **Core**: React 19, TypeScript, Vite
- **Desktop**: Electron, Tesseract.js (OCR), LocalForage
- **Mobile**: Capacitor (iOS)
- **UI**: Custom CSS + Lucide Icons

---

## Install & Run

### Requirements
- Node.js v18 or higher
- npm

### 1. Desktop App

```bash
cd deskapp
npm install
npm run dev          # Development mode
npm run build        # Build production app
```

### 2. iOS App (phoneapp)

```bash
cd phoneapp
npm install
npm run dev          # Development mode
npm run build
npx cap sync ios
npx cap open ios     # Open in Xcode
```

---

## Code Quality

```bash
npm run lint         # Run Oxlint
```

---

## Keywords

`expense tracker` `personal finance app` `budget app` `receipt OCR` `AI spending assistant` `Electron React` `Capacitor iOS` `money management` `spending tracker`
