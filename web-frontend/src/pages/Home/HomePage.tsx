import { Card, Row, Col, Statistic, Typography, Space, Tag } from 'antd';
import {
  ThunderboltOutlined,
  RocketOutlined,
  SwapOutlined,
  TrophyOutlined,
  ExperimentOutlined,
} from '@ant-design/icons';
import { useUIStore } from '../../stores';
import { WelcomeIllustration, AlgorithmIllustration, ComparisonIllustration } from '../../components/illustrations';
import { ALGORITHMS, CATEGORY_NAMES, BENCHMARK_FUNCTIONS } from '../../constants';

const { Title, Text } = Typography;

export function HomePage() {
  const { setCurrentPage } = useUIStore();

  const algorithmCount = ALGORITHMS.length;
  const benchmarkCount = BENCHMARK_FUNCTIONS.length;

  const algorithmsByCategory = ALGORITHMS.reduce((acc, alg) => {
    acc[alg.category] = (acc[alg.category] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  const getCategoryColor = (category: string) => {
    const colors: Record<string, string> = {
      swarm: 'blue',
      evolutionary: 'green',
      physics: 'orange',
      hybrid: 'purple',
    };
    return colors[category] || 'default';
  };

  return (
    <div style={{ padding: 24 }}>
      {/* 页面标题 */}
      <div style={{ marginBottom: 24 }}>
        <Title level={2} style={{ marginBottom: 8 }}>元启发式优化算法平台</Title>
        <Text type="secondary">支持多种元启发式优化算法的对比分析和性能评估</Text>
      </div>

      {/* 统计卡片 */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} sm={12} lg={6}>
          <Card hoverable>
            <Statistic
              title="算法总数"
              value={algorithmCount}
              prefix={<ThunderboltOutlined style={{ color: '#1677ff' }} />}
              valueStyle={{ color: '#1677ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card hoverable>
            <Statistic
              title="基准函数"
              value={benchmarkCount}
              prefix={<TrophyOutlined style={{ color: '#52c41a' }} />}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card hoverable>
            <Statistic
              title="算法类别"
              value={Object.keys(algorithmsByCategory).length}
              prefix={<SwapOutlined style={{ color: '#722ed1' }} />}
              valueStyle={{ color: '#722ed1' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card hoverable>
            <Statistic
              title="优化运行"
              value={0}
              prefix={<RocketOutlined style={{ color: '#fa8c16' }} />}
              valueStyle={{ color: '#fa8c16' }}
            />
          </Card>
        </Col>
      </Row>

      {/* 快速开始卡片 */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} lg={12}>
          <Card
            hoverable
            style={{ height: '100%', cursor: 'pointer' }}
            onClick={() => setCurrentPage('comparison')}
          >
            <Space direction="vertical" size="middle" style={{ width: '100%' }}>
              <ComparisonIllustration size="sm" primaryColor="#1677ff" />
              <Title level={4} style={{ margin: 0 }}>算法对比</Title>
              <Text type="secondary">选择多个算法进行性能对比分析</Text>
            </Space>
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card
            hoverable
            style={{ height: '100%', cursor: 'pointer' }}
            onClick={() => setCurrentPage('optimize')}
          >
            <Space direction="vertical" size="middle" style={{ width: '100%' }}>
              <AlgorithmIllustration size="sm" primaryColor="#52c41a" />
              <Title level={4} style={{ margin: 0 }}>单次优化</Title>
              <Text type="secondary">运行单个算法并查看详细结果</Text>
            </Space>
          </Card>
        </Col>
      </Row>

      {/* 算法概览 */}
      <Card title="算法概览" style={{ marginBottom: 24 }}>
        <Row gutter={[16, 16]}>
          {Object.entries(algorithmsByCategory).map(([category, count]) => (
            <Col xs={24} sm={12} lg={6} key={category}>
              <Card
                size="small"
                style={{ background: 'rgba(0,0,0,0.02)' }}
                styles={{ body: { padding: '16px' } }}
              >
                <Space direction="vertical" size={4} style={{ width: '100%' }}>
                  <Tag color={getCategoryColor(category)}>
                    {CATEGORY_NAMES[category as keyof typeof CATEGORY_NAMES] || category}
                  </Tag>
                  <Text strong style={{ fontSize: 24 }}>{count}</Text>
                  <Text type="secondary" style={{ fontSize: 12 }}>种算法</Text>
                </Space>
              </Card>
            </Col>
          ))}
        </Row>
      </Card>

      {/* 欢迎区域 */}
      <Card
        style={{
          background: 'linear-gradient(135deg, #e6f4ff 0%, #f0f5ff 50%, #fff7e6 100%)',
          border: 'none',
        }}
        styles={{ body: { padding: '32px' } }}
      >
        <Row gutter={[32, 32]} align="middle">
          <Col xs={24} lg={12}>
            <WelcomeIllustration
              size="lg"
              title="开始您的优化之旅"
              description="探索多种元启发式算法，找到最优解决方案"
            />
          </Col>
          <Col xs={24} lg={12}>
            <Space direction="vertical" size="large" style={{ width: '100%' }}>
              <Title level={4}>平台特性</Title>
              <Space direction="vertical" style={{ width: '100%' }}>
                <Card size="small" hoverable>
                  <Space>
                    <SwapOutlined style={{ fontSize: 24, color: '#1677ff' }} />
                    <div>
                      <Text strong>算法对比</Text>
                      <br />
                      <Text type="secondary" style={{ fontSize: 12 }}>多算法并行对比分析</Text>
                    </div>
                  </Space>
                </Card>
                <Card size="small" hoverable>
                  <Space>
                    <ExperimentOutlined style={{ fontSize: 24, color: '#52c41a' }} />
                    <div>
                      <Text strong>收敛分析</Text>
                      <br />
                      <Text type="secondary" style={{ fontSize: 12 }}>可视化收敛曲线</Text>
                    </div>
                  </Space>
                </Card>
                <Card size="small" hoverable>
                  <Space>
                    <TrophyOutlined style={{ fontSize: 24, color: '#fa8c16' }} />
                    <div>
                      <Text strong>性能评估</Text>
                      <br />
                      <Text type="secondary" style={{ fontSize: 12 }}>全面的性能指标</Text>
                    </div>
                  </Space>
                </Card>
              </Space>
            </Space>
          </Col>
        </Row>
      </Card>
    </div>
  );
}
