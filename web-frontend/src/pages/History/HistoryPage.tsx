import { Card, Typography } from 'antd';
import { EmptyDataIllustration } from '../../components/illustrations';

const { Title, Text } = Typography;

export function HistoryPage() {
  return (
    <div style={{ padding: 24 }}>
      <div style={{ marginBottom: 24 }}>
        <Title level={2} style={{ marginBottom: 8 }}>历史记录</Title>
        <Text type="secondary">查看过去的优化运行记录</Text>
      </div>

      <Card>
        <div style={{ height: 400, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <EmptyDataIllustration
            size="lg"
            title="暂无历史记录"
            description="运行优化后，结果将保存在这里"
          />
        </div>
      </Card>
    </div>
  );
}
