/**
 * 算法选择器组件
 * 支持单选和多选模式
 */

import { memo, type MouseEvent, type KeyboardEvent } from 'react';
import { Card, Space, Tag, Button, Typography } from 'antd';
import { CheckOutlined, CloseOutlined } from '@ant-design/icons';
import { CATEGORY_NAMES, getAlgorithmColor } from '../../constants';
import type { Algorithm } from '../../types';

const { Text } = Typography;

interface AlgorithmSelectorProps {
  algorithms: Algorithm[];
  selectedIds: string[];
  onToggle: (id: string) => void;
  onSelectAll: () => void;
  onClear: () => void;
  algorithmsByCategory?: Record<string, Algorithm[]>;
  mode?: 'single' | 'multi';
  showCount?: boolean;
  total?: number;
}

const AlgorithmSelectorInner = ({
  algorithms,
  selectedIds,
  onToggle,
  onSelectAll,
  onClear,
  algorithmsByCategory,
  mode = 'multi',
  showCount = true,
  total,
}: AlgorithmSelectorProps) => {
  // 使用传入的分组或重新计算
  const groupedAlgorithms = algorithmsByCategory || algorithms.reduce((acc, alg) => {
    if (!acc[alg.category]) {
      acc[alg.category] = [];
    }
    acc[alg.category].push(alg);
    return acc;
  }, {} as Record<string, Algorithm[]>);

  const handleTagClick = (_e: MouseEvent<HTMLSpanElement>, id: string) => {
    onToggle(id);
  };

  const handleTagKeyDown = (e: KeyboardEvent<HTMLSpanElement>, id: string) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onToggle(id);
    }
  };

  return (
    <Card
      title={
        <Space>
          <span>选择算法</span>
          {showCount && (
            <Tag color="blue">
              {selectedIds.length}/{total || algorithms.length}
            </Tag>
          )}
        </Space>
      }
      extra={
        mode === 'multi' && (
          <Space>
            <Button
              icon={<CheckOutlined />}
              onClick={onSelectAll}
              className="algorithm-btn-enhanced"
              style={{
                height: 56,
                fontSize: 16,
                padding: '12px 24px',
                borderRadius: 8,
              }}
            >
              全选
            </Button>
            <Button
              icon={<CloseOutlined />}
              onClick={onClear}
              className="algorithm-btn-enhanced"
              style={{
                height: 56,
                fontSize: 16,
                padding: '12px 24px',
                borderRadius: 8,
              }}
            >
              清空
            </Button>
          </Space>
        )
      }
    >
      <Space direction="vertical" size="middle" style={{ width: '100%' }}>
        {Object.entries(groupedAlgorithms).map(([category, algs]) => (
          <div key={category}>
            <Text type="secondary" style={{ marginBottom: 8, display: 'block' }}>
              {CATEGORY_NAMES[category as keyof typeof CATEGORY_NAMES] || category}
            </Text>
            <Space wrap>
              {algs.map((alg) => (
                <Tag
                  key={alg.id}
                  color={selectedIds.includes(alg.id) ? getAlgorithmColor(alg.id) : 'default'}
                  className="algorithm-tag-enhanced"
                  style={{
                    height: 48,
                    fontSize: 16,
                    padding: '10px 20px',
                    margin: '8px',
                    borderRadius: 8,
                    cursor: 'pointer',
                    display: 'inline-flex',
                    alignItems: 'center',
                    minWidth: 100,
                  }}
                  onClick={(e) => handleTagClick(e, alg.id)}
                  onKeyDown={(e) => handleTagKeyDown(e, alg.id)}
                  role="checkbox"
                  aria-checked={selectedIds.includes(alg.id)}
                  tabIndex={0}
                >
                  {alg.name}
                </Tag>
              ))}
            </Space>
          </div>
        ))}
      </Space>
    </Card>
  );
};

// 使用自定义比较函数避免不必要的重渲染
const arePropsEqual = (prevProps: AlgorithmSelectorProps, nextProps: AlgorithmSelectorProps) => {
  return (
    prevProps.selectedIds.length === nextProps.selectedIds.length &&
    prevProps.selectedIds.every((id, index) => id === nextProps.selectedIds[index]) &&
    prevProps.algorithms === nextProps.algorithms &&
    prevProps.algorithmsByCategory === nextProps.algorithmsByCategory
  );
};

export const AlgorithmSelector = memo(AlgorithmSelectorInner, arePropsEqual);
