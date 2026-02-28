import { useEffect, Suspense, lazy } from 'react';
import { ConfigProvider, App as AntApp, theme, Spin } from 'antd';
import zhCN from 'antd/locale/zh_CN';
import { MainLayout } from './components/layout';
import { ErrorBoundary } from './components/feedback/ErrorBoundary';
import { useUIStore } from './stores';
import { lightToken, darkToken, componentTokens } from './theme';

const HomePage = lazy(() => import('./pages/Home').then(m => ({ default: m.HomePage })));
const ComparisonPage = lazy(() => import('./pages/Comparison').then(m => ({ default: m.ComparisonPage })));
const OptimizePage = lazy(() => import('./pages/Optimize').then(m => ({ default: m.OptimizePage })));
const HistoryPage = lazy(() => import('./pages/History').then(m => ({ default: m.HistoryPage })));
const SettingsPage = lazy(() => import('./pages/Settings').then(m => ({ default: m.SettingsPage })));

const MOComparisonPage = lazy(() => import('./pages/MOComparison/MOComparisonPage').then(m => ({ default: m.MOComparisonPage })));

function PageLoader() {
  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: '100vh',
      padding: 24
    }}>
      <Spin size="large" tip="加载中..." />
    </div>
  );
}

function App() {
  const { currentPage, theme: appTheme } = useUIStore();
  const isDark = appTheme === 'dark';

  useEffect(() => {
    const root = document.documentElement;
    if (isDark) {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
  }, [isDark]);

  const renderPage = () => {
    switch (currentPage) {
      case 'home':
        return <HomePage />;
      case 'comparison':
        return <ComparisonPage />;
      case 'moComparison':
        return <MOComparisonPage />;
      case 'optimize':
        return <OptimizePage />;
      case 'history':
        return <HistoryPage />;
      case 'settings':
        return <SettingsPage />;
      default: {
        const _exhaustiveCheck: never = currentPage;
        console.error('未处理的页面类型:', _exhaustiveCheck);
        return <HomePage />;
      }
    }
  };

  return (
    <ErrorBoundary>
      <ConfigProvider
        locale={zhCN}
        theme={{
          algorithm: isDark ? theme.darkAlgorithm : theme.defaultAlgorithm,
          token: isDark ? { ...lightToken, ...darkToken } : lightToken,
          components: componentTokens,
        }}
      >
        <AntApp>
          <MainLayout>
            <div className="min-h-screen">
              <Suspense fallback={<PageLoader />}>
                {renderPage()}
              </Suspense>
            </div>
          </MainLayout>
        </AntApp>
      </ConfigProvider>
    </ErrorBoundary>
  );
}

export default App;
