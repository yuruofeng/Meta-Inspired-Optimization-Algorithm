/**
 * UI状态管理
 */

import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface UIState {
  // 侧边栏状态
  sidebarCollapsed: boolean;

  // 主题
  theme: 'light' | 'dark';

  // 当前页面
  currentPage: string;

  // Actions
  toggleSidebar: () => void;
  setSidebarCollapsed: (collapsed: boolean) => void;
  toggleTheme: () => void;
  setCurrentPage: (page: string) => void;
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
