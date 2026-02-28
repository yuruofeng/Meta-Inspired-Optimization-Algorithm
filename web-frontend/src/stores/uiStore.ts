/**
 * UI状态管理
 */

import { create } from 'zustand';
import { persist } from 'zustand/middleware';

// 页面名称联合类型
export type PageName = 'home' | 'comparison' | 'optimize' | 'history' | 'settings';

interface UIState {
  // 侧边栏状态
  sidebarCollapsed: boolean;

  // 主题
  theme: 'light' | 'dark';

  // 当前页面
  currentPage: PageName;

  // Actions
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
