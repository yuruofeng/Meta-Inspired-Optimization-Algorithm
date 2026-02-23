/**
 * 加载状态组件
 * 使用 Ant Design Skeleton 和 Spin
 */

import { Skeleton, Spin, Typography, Space, Card } from 'antd';
import { LoadingOutlined } from '@ant-design/icons';
import { LoadingIllustration } from '../illustrations';

const { Title, Text } = Typography;

export type LoadingType = 'skeleton' | 'spin' | 'illustration';

type IllustrationSizeInternal = 'sm' | 'md' | 'lg' | 'xl';

interface LoadingStateProps {
  type?: LoadingType;
  title?: string;
  description?: string;
  size?: IllustrationSizeInternal;
  showCard?: boolean;
  loading?: boolean;
  children?: React.ReactNode;
  skeletonConfig?: {
    rows?: number;
    avatar?: boolean;
    active?: boolean;
  };
}

// 页面骨架屏
export function PageSkeleton({ rows = 4, avatar = false, active = true }: {
  rows?: number;
  avatar?: boolean;
  active?: boolean;
}) {
  return (
    <div style={{ padding: 24 }}>
      <Skeleton active={active} avatar={avatar} paragraph={{ rows }} />
    </div>
  );
}

// 卡片骨架屏
export function CardSkeleton({ active = true }: { active?: boolean }) {
  return (
    <Card>
      <Skeleton active={active} avatar paragraph={{ rows: 2 }} />
    </Card>
  );
}

// 列表骨架屏
export function ListSkeleton({ count = 3, active = true }: {
  count?: number;
  active?: boolean;
}) {
  return (
    <Space direction="vertical" style={{ width: '100%' }} size="middle">
      {Array.from({ length: count }).map((_, index) => (
        <Card key={index} size="small">
          <Skeleton active={active} avatar paragraph={{ rows: 1 }} />
        </Card>
      ))}
    </Space>
  );
}

// 表格骨架屏
export function TableSkeleton({ rows = 5, active = true }: {
  rows?: number;
  active?: boolean;
}) {
  return (
    <div>
      <div style={{ display: 'flex', gap: 16, marginBottom: 16 }}>
        {Array.from({ length: 4 }).map((_, i) => (
          <Skeleton.Input key={i} active={active} style={{ width: 120 }} />
        ))}
      </div>
      {Array.from({ length: rows }).map((_, index) => (
        <div key={index} style={{ display: 'flex', gap: 16, marginBottom: 12 }}>
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton.Input key={i} active={active} size="small" style={{ width: 120 }} />
          ))}
        </div>
      ))}
    </div>
  );
}

export function LoadingState({
  type = 'spin',
  title,
  description,
  size = 'lg',
  showCard = false,
  loading = true,
  children,
  skeletonConfig = {},
}: LoadingStateProps) {
  if (!loading && children) {
    return <>{children}</>;
  }

  const content = (() => {
    switch (type) {
      case 'illustration':
        return (
          <div className="loading-state">
            <LoadingIllustration
              size={size}
              title={title}
              description={description}
            />
          </div>
        );

      case 'skeleton':
        return (
          <PageSkeleton
            rows={skeletonConfig.rows || 4}
            avatar={skeletonConfig.avatar || false}
            active={skeletonConfig.active !== false}
          />
        );

      case 'spin':
      default:
        return (
          <div className="loading-state">
            <Spin
              indicator={<LoadingOutlined style={{ fontSize: 48 }} spin />}
            />
            {title && <Title level={4} style={{ marginTop: 16 }}>{title}</Title>}
            {description && <Text type="secondary">{description}</Text>}
          </div>
        );
    }
  })();

  if (showCard) {
    return <Card>{content}</Card>;
  }

  return content;
}
