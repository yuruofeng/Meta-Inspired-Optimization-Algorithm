import { Layout, Menu, Switch, Typography } from 'antd';
import type { MenuProps } from 'antd';
import {
  HomeOutlined,
  SwapOutlined,
  PlayCircleOutlined,
  HistoryOutlined,
  SettingOutlined,
  SunOutlined,
  MoonOutlined,
  ApartmentOutlined,
} from '@ant-design/icons';
import { useUIStore, type PageName } from '../../../stores';

const { Sider } = Layout;

type MenuItem = Required<MenuProps>['items'][number];

const menuItems: MenuItem[] = [
  {
    key: 'home',
    icon: <HomeOutlined />,
    label: '首页',
  },
  {
    key: 'comparison',
    icon: <SwapOutlined />,
    label: '单目标对比',
  },
  {
    key: 'moComparison',
    icon: <ApartmentOutlined />,
    label: '多目标对比',
  },
  {
    key: 'optimize',
    icon: <PlayCircleOutlined />,
    label: '单次优化',
  },
  {
    key: 'history',
    icon: <HistoryOutlined />,
    label: '历史记录',
  },
  {
    key: 'settings',
    icon: <SettingOutlined />,
    label: '设置',
  },
];

export function AppSidebar() {
  const { sidebarCollapsed, setSidebarCollapsed, theme, toggleTheme, currentPage, setCurrentPage } = useUIStore();

  const handleMenuClick = ({ key }: { key: string }) => {
    setCurrentPage(key as PageName);
  };

  return (
    <Sider
      collapsible
      collapsed={sidebarCollapsed}
      onCollapse={setSidebarCollapsed}
      breakpoint="lg"
      collapsedWidth={80}
      width={240}
      style={{
        overflow: 'auto',
        height: '100vh',
        position: 'fixed',
        left: 0,
        top: 0,
        bottom: 0,
      }}
      trigger={null}
    >
      <div
        style={{
          height: 64,
          display: 'flex',
          alignItems: 'center',
          justifyContent: sidebarCollapsed ? 'center' : 'flex-start',
          padding: sidebarCollapsed ? 0 : '0 24px',
          borderBottom: '1px solid rgba(255, 255, 255, 0.1)',
        }}
      >
        <div
          style={{
            width: 32,
            height: 32,
            background: 'linear-gradient(135deg, #1677ff 0%, #722ed1 100%)',
            borderRadius: 8,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
          }}
        >
          <span style={{ color: 'white', fontWeight: 'bold', fontSize: 14 }}>MH</span>
        </div>
        {!sidebarCollapsed && (
          <Typography.Text
            strong
            style={{ color: 'rgba(255, 255, 255, 0.88)', marginLeft: 12, fontSize: 14 }}
          >
            元启发式优化
          </Typography.Text>
        )}
      </div>

      <Menu
        theme="dark"
        mode="inline"
        selectedKeys={[currentPage]}
        items={menuItems}
        onClick={handleMenuClick}
        style={{ borderRight: 0 }}
        role="navigation"
        aria-label="主导航菜单"
      />

      <div
        style={{
          position: 'absolute',
          bottom: 0,
          left: 0,
          right: 0,
          padding: '16px',
          borderTop: '1px solid rgba(255, 255, 255, 0.1)',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: sidebarCollapsed ? 'center' : 'space-between',
          }}
        >
          {!sidebarCollapsed && (
            <Typography.Text style={{ color: 'rgba(255, 255, 255, 0.65)', fontSize: 14 }}>
              {theme === 'light' ? '深色模式' : '浅色模式'}
            </Typography.Text>
          )}
          <Switch
            checked={theme === 'dark'}
            onChange={toggleTheme}
            checkedChildren={<MoonOutlined />}
            unCheckedChildren={<SunOutlined />}
          />
        </div>
      </div>
    </Sider>
  );
}
