/**
 * Ant Design 设计令牌配置
 */

import type { ThemeConfig } from 'antd';

// 浅色主题令牌
export const lightToken = {
  // 主色
  colorPrimary: '#1677ff',
  // 功能色
  colorSuccess: '#52c41a',
  colorWarning: '#faad14',
  colorError: '#ff4d4f',
  colorInfo: '#1677ff',
  // 圆角
  borderRadius: 8,
  borderRadiusLG: 12,
  borderRadiusSM: 6,
  // 字体
  fontSize: 14,
  fontSizeLG: 16,
  fontSizeSM: 12,
  // 间距
  padding: 16,
  paddingLG: 24,
  paddingSM: 12,
  // 阴影
  boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.03), 0 1px 6px -1px rgba(0, 0, 0, 0.02), 0 2px 4px 0 rgba(0, 0, 0, 0.02)',
  boxShadowSecondary: '0 6px 16px 0 rgba(0, 0, 0, 0.08), 0 3px 6px -4px rgba(0, 0, 0, 0.12), 0 9px 28px 8px rgba(0, 0, 0, 0.05)',
};

// 深色主题令牌
export const darkToken = {
  // 主色
  colorPrimary: '#1677ff',
  // 背景色
  colorBgContainer: '#1f1f1f',
  colorBgElevated: '#262626',
  colorBgLayout: '#141414',
  // 边框色
  colorBorder: '#424242',
  colorBorderSecondary: '#363636',
  // 文字色
  colorText: 'rgba(255, 255, 255, 0.88)',
  colorTextSecondary: 'rgba(255, 255, 255, 0.65)',
  colorTextTertiary: 'rgba(255, 255, 255, 0.45)',
  // 功能色（深色模式调整）
  colorSuccess: '#49aa19',
  colorWarning: '#d89614',
  colorError: '#a61d24',
  colorInfo: '#177ddc',
};

// 算法类别颜色（保留原有语义）
export const algorithmCategoryColors = {
  swarm: {
    primary: '#3B82F6',
    light: '#60A5FA',
    dark: '#2563EB',
    name: '群智能算法',
  },
  evolutionary: {
    primary: '#10B981',
    light: '#34D399',
    dark: '#059669',
    name: '进化算法',
  },
  physics: {
    primary: '#F59E0B',
    light: '#FBBF24',
    dark: '#D97706',
    name: '物理启发算法',
  },
  hybrid: {
    primary: '#8B5CF6',
    light: '#A78BFA',
    dark: '#7C3AED',
    name: '混合算法',
  },
} as const;

// 组件级别主题配置
export const componentTokens = {
  Menu: {
    itemBorderRadius: 8,
    subMenuItemBorderRadius: 8,
  },
  Card: {
    borderRadiusLG: 12,
  },
  Button: {
    borderRadius: 6,
    controlHeight: 36,
    controlHeightLG: 44,
    controlHeightSM: 28,
  },
  Input: {
    borderRadius: 6,
    controlHeight: 36,
  },
  Select: {
    borderRadius: 6,
    controlHeight: 36,
  },
  Table: {
    borderRadiusLG: 12,
  },
  Modal: {
    borderRadiusLG: 12,
  },
  Drawer: {
    borderRadiusLG: 12,
  },
};

// 获取主题配置
export function getThemeConfig(isDark: boolean): ThemeConfig {
  return {
    algorithm: isDark ? undefined : undefined, // 使用默认算法
    token: isDark ? darkToken : lightToken,
    components: componentTokens,
  };
}
