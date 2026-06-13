/**
 * 运行参数表单组件
 */

import { Card, Space, InputNumber, Typography } from 'antd';
import { SettingOutlined } from '@ant-design/icons';

const { Text } = Typography;

interface RunParamsCardProps {
  populationSize: number;
  maxIterations: number;
  runs?: number;
  onPopulationSizeChange: (value: number) => void;
  onMaxIterationsChange: (value: number) => void;
  onRunsChange?: (value: number) => void;
  showRuns?: boolean;
}

export function RunParamsCard({
  populationSize,
  maxIterations,
  runs,
  onPopulationSizeChange,
  onMaxIterationsChange,
  onRunsChange,
  showRuns = false,
}: RunParamsCardProps) {
  return (
    <Card title={<Space><SettingOutlined /><span>运行参数</span></Space>}>
      <Space direction="vertical" size="middle" style={{ width: '100%' }}>
        <div>
          <Text type="secondary" style={{ marginBottom: 4, display: 'block' }}>
            种群大小
          </Text>
          <InputNumber
            value={populationSize}
            onChange={(v) => onPopulationSizeChange(v || 30)}
            min={5}
            max={1000}
            style={{ width: '100%' }}
          />
        </div>
        <div>
          <Text type="secondary" style={{ marginBottom: 4, display: 'block' }}>
            最大迭代次数
          </Text>
          <InputNumber
            value={maxIterations}
            onChange={(v) => onMaxIterationsChange(v || 500)}
            min={1}
            max={10000}
            style={{ width: '100%' }}
          />
        </div>
        {showRuns && runs !== undefined && onRunsChange && (
          <div>
            <Text type="secondary" style={{ marginBottom: 4, display: 'block' }}>
              独立运行次数
            </Text>
            <InputNumber
              value={runs}
              onChange={(v) => onRunsChange(v || 1)}
              min={1}
              max={100}
              style={{ width: '100%' }}
            />
          </div>
        )}
      </Space>
    </Card>
  );
}
