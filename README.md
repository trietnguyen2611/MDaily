# MDaily

MDaily is a personal expense management app for both Desktop and Mobile. It has a simple, modern design and focuses on good user experience.

## Main Features

- **Expense Management**: Record spending, sort by category, add photos and notes.
- **Receipt Recognition (OCR & AI)**: Automatically get expense information from receipt images.
- **Statistics & Reports**: Track limits and see how money is spent clearly.
- **AI Assistant**: Give advice and analyze personal money habits.
- **Simple Design**: Interface inspired by Apple Design System. Smooth and easy to use.

## Project Structure

```text
MDaily/
├── deskapp/       # Desktop app (Electron + React + TypeScript + Vite)
├── phoneapp/      # Mobile iOS app (Capacitor + React + TypeScript + Vite)
├── DESIGN.md      # Design rules for the interface (Design System)
└── MDaily.png     # App brand logo
```

## Technologies Used

- **Core**: React 19, TypeScript, Vite
- **Desktop**: Electron, Tesseract.js, LocalForage
- **Mobile**: Capacitor (iOS)
- **UI & Icons**: Custom CSS, Lucide Icons

## Install & Run

### System Requirements
- Node.js (v18 or higher)
- npm

### 1. Desktop App (`deskapp`)

```bash
cd deskapp
npm install

# Run development environment
npm run dev

# Build the Desktop app
npm run build
```

### 2. Mobile App (`phoneapp`)

```bash
cd phoneapp
npm install

# Run development environment
npm run dev

# Build for iOS with Capacitor
npm run build
npx cap sync ios
npx cap open ios
```

## Check Source Code

Use Oxlint to check code quality:

```bash
npm run lint
```
