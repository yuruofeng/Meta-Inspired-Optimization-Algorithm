import { Card, Row, Col, Typography, Space, Switch, Divider, Form } from 'antd';
import {
  SettingOutlined,
  SlidersOutlined,
  BgColorsOutlined,
  DatabaseOutlined,
} from '@ant-design/icons';
import { EmptyDataIllustration } from '../../components/illustrations';
import { useUIStore } from '../../stores';

const { Title, Text } = Typography;

export function SettingsPage() {
  const { theme, toggleTheme } = useUIStore();

  return (
    <div style={{ padding: 24 }}>
      <div style={{ marginBottom: 24 }}>
        <Title level={2} style={{ marginBottom: 8 }}>
          <Space>
            <SettingOutlined />
            <span>设置</span>
          </Space>
        </Title>
        <Text type="secondary">配置系统参数和偏好设置</Text>
      </div>

      <Row gutter={[24, 24]} style={{ marginBottom: 24 }}>
        <Col xs={24} md={12} lg={8}>
          <Card hoverable style={{ height: '100%' }}>
            <Space direction="vertical" size="middle" style={{ width: '100%' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ padding: 8, background: 'rgba(22, 119, 255, 0.1)', borderRadius: 8 }}>
                  <SlidersOutlined style={{ fontSize: 20, color: '#1677ff' }} />
                </div>
                <Title level={5} style={{ margin: 0 }}>算法配置</Title>
              </div>
              <Text type="secondary">自定义算法的默认参数和行为设置</Text>
            </Space>
          </Card>
        </Col>

        <Col xs={24} md={12} lg={8}>
          <Card hoverable style={{ height: '100%' }}>
            <Space direction="vertical" size="middle" style={{ width: '100%' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ padding: 8, background: 'rgba(114, 46, 209, 0.1)', borderRadius: 8 }}>
                  <BgColorsOutlined style={{ fontSize: 20, color: '#722ed1' }} />
                </div>
                <Title level={5} style={{ margin: 0 }}>外观主题</Title>
              </div>
              <Text type="secondary">调整界面颜色、字体和显示偏好</Text>
            </Space>
          </Card>
        </Col>

        <Col xs={24} md={12} lg={8}>
          <Card hoverable style={{ height: '100%' }}>
            <Space direction="vertical" size="middle" style={{ width: '100%' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ padding: 8, background: 'rgba(82, 196, 26, 0.1)', borderRadius: 8 }}>
                  <DatabaseOutlined style={{ fontSize: 20, color: '#52c41a' }} />
                </div>
                <Title level={5} style={{ margin: 0 }}>数据管理</Title>
              </div>
              <Text type="secondary">管理历史记录和数据导出设置</Text>
            </Space>
          </Card>
        </Col>
      </Row>

      <Card title="外观设置">
        <Form layout="vertical">
          <Form.Item label="主题模式">
            <Space>
              <Switch
                checked={theme === 'dark'}
                onChange={toggleTheme}
                checkedChildren="深色"
                unCheckedChildren="浅色"
              />
              <Text type="secondary">当前: {theme === 'dark' ? '深色模式' : '浅色模式'}</Text>
            </Space>
          </Form.Item>
        </Form>

        <Divider />

        <div style={{ height: 200, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <EmptyDataIllustration
            size="md"
            title="更多设置开发中"
            description="更多自定义选项即将推出，敬请期待"
          />
        </div>
      </Card>
    </div>
  );
}
