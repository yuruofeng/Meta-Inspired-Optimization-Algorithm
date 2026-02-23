import { useEffect } from 'react';
import { ConfigProvider, App as AntApp, theme } from 'antd';
import zhCN from 'antd/locale/zh_CN';
import { MainLayout } from './components/layout';
import { HomePage } from './pages/Home';
import { ComparisonPage } from './pages/Comparison';
import { OptimizePage } from './pages/Optimize';
import { HistoryPage } from './pages/History';
import { SettingsPage } from './pages/Settings';
import { useUIStore } from './stores';
import { lightToken, darkToken, componentTokens } from './theme';

function App() {
  const { currentPage, theme: appTheme } = useUIStore();
  const isDark = appTheme === 'dark';

  // 同步主题到 HTML 根元素
  useEffect(() => {
    const root = document.documentElement;
    if (isDark) {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
  }, [isDark]);

  // 根据当前页面状态渲染不同内容
  const renderPage = () => {
    switch (currentPage) {
      case 'home':
        return <HomePage />;
      case 'comparison':
        return <ComparisonPage />;
      case 'optimize':
        return <OptimizePage />;
      case 'history':
        return <HistoryPage />;
      case 'settings':
        return <SettingsPage />;
      default:
        return <HomePage />;
    }
  };

  return (
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
            {renderPage()}
          </div>
        </MainLayout>
      </AntApp>
    </ConfigProvider>
  );
}

export default App;
