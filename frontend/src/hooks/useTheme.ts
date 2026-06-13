import { useUIStore } from '../stores';

export function useTheme() {
  const theme = useUIStore((state) => state.theme);
  const isDark = theme === 'dark';

  return {
    theme,
    isDark,
    toggleTheme: useUIStore((state) => state.toggleTheme),
  };
}
