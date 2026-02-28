/**
 * UI状态管理
 */

import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export type PageName = 'home' | 'comparison' | 'moComparison' | 'optimize' | 'history' | 'settings';

interface UIState {
  sidebarCollapsed: boolean;
  theme: 'light' | 'dark';
  currentPage: PageName;

  toggleSidebar: () => void;
  setSidebarCollapsed: (collapsed: boolean) => void;
  toggleTheme: () => void;
  setCurrentPage: (page: PageName) => void;
}

export const useUIStore = create<UIState>()(
  persist(
    (set) => ({
      sidebarCollapsed: false,
      theme: 'light',
      currentPage: 'home',

      toggleSidebar: () => set((state) => ({ sidebarCollapsed: !state.sidebarCollapsed })),
      setSidebarCollapsed: (collapsed) => set({ sidebarCollapsed: collapsed }),
      toggleTheme: () => set((state) => ({ theme: state.theme === 'light' ? 'dark' : 'light' })),
      setCurrentPage: (page) => set({ currentPage: page }),
    }),
    {
      name: 'ui-storage',
      partialize: (state) => ({ sidebarCollapsed: state.sidebarCollapsed, theme: state.theme }),
    }
  )
);
