import type { ReactNode } from 'react';
import { Layout } from 'antd';
import { AppSidebar } from '../AppSidebar';
import { useUIStore } from '../../../stores';

const { Content } = Layout;

interface MainLayoutProps {
  children: ReactNode;
}

export function MainLayout({ children }: MainLayoutProps) {
  const { sidebarCollapsed } = useUIStore();

  return (
    <Layout className="min-h-screen">
      <AppSidebar />
      <Layout
        style={{
          marginLeft: sidebarCollapsed ? 80 : 240,
          transition: 'margin-left 0.2s',
        }}
      >
        <Content
          className="min-h-screen bg-gray-50 dark:bg-gray-900"
          style={{
            margin: 0,
            padding: 0,
          }}
          role="main"
          aria-label="主内容区域"
        >
          {children}
        </Content>
      </Layout>
    </Layout>
  );
}
