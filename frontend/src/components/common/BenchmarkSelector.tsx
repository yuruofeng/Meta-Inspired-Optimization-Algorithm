/**
 * 基准函数选择器组件
 */

import { memo } from 'react';
import { Card, Select, Space, Typography } from 'antd';
import type { BenchmarkFunction } from '../../types';

const { Text } = Typography;

interface BenchmarkSelectorProps {
  benchmarks: BenchmarkFunction[];
  selectedId: string;
  onChange: (id: string) => void;
  showDetails?: boolean;
}

const BenchmarkSelectorInner = ({
  benchmarks,
  selectedId,
  onChange,
  showDetails = true,
}: BenchmarkSelectorProps) => {
  const selectedBenchmark = benchmarks.find((f) => f.id === selectedId);

  return (
    <Card title="基准函数">
      <Select
        value={selectedId}
        onChange={onChange}
        style={{ width: '100%' }}
        options={benchmarks.map((func) => ({
          label: `${func.id} - ${func.name}`,
          value: func.id,
        }))}
      />
      {showDetails && selectedBenchmark && (
        <div style={{ marginTop: 16 }}>
          <Space direction="vertical" size={8} style={{ width: '100%' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <Text type="secondary">类型</Text>
              <Text>{selectedBenchmark.type}</Text>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <Text type="secondary">维度</Text>
              <Text>{selectedBenchmark.dimension}</Text>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <Text type="secondary">最优值</Text>
              <Text>{selectedBenchmark.optimalValue}</Text>
            </div>
          </Space>
        </div>
      )}
    </Card>
  );
};

const arePropsEqual = (prevProps: BenchmarkSelectorProps, nextProps: BenchmarkSelectorProps) => {
  return (
    prevProps.selectedId === nextProps.selectedId &&
    prevProps.benchmarks === nextProps.benchmarks &&
    prevProps.showDetails === nextProps.showDetails
  );
};

export const BenchmarkSelector = memo(BenchmarkSelectorInner, arePropsEqual);
