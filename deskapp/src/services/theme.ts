export type ThemeMode = 'system' | 'light' | 'dark'

const THEME_STORAGE_KEY = 'mdaily_theme'

export function getThemeMode(): ThemeMode {
  const saved = localStorage.getItem(THEME_STORAGE_KEY)
  return saved === 'light' || saved === 'dark' ? saved : 'system'
}

export function setThemeMode(mode: ThemeMode) {
  localStorage.setItem(THEME_STORAGE_KEY, mode)
}

export function getEffectiveDarkMode(mode: ThemeMode): boolean {
  return mode === 'dark' || (mode === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches)
}
