import { useState, useMemo, useRef, useEffect } from 'react';
import {
  Card,
  Row,
  Col,
  Typography,
  Select,
  InputNumber,
  Button,
  Space,
  Tag,
  Table,
  message,
  Statistic,
} from 'antd';
import {
  PlayCircleOutlined,
  DownloadOutlined,
  CheckOutlined,
  CloseOutlined,
  LineChartOutlined,
} from '@ant-design/icons';
import { MO_ALGORITHMS, MO_PROBLEMS, MO_PROBLEM_TYPE_NAMES, getMOAlgorithmColor } from '../../constants';
import { EmptyDataIllustration, LoadingIllustration, ServerErrorIllustration } from '../../components/illustrations';
import { toExponentialSafe, toFixedSafe } from '../../utils/arrayUtils';
import { errorLogger } from '../../utils/errorLogger';

const { Title, Text } = Typography;

interface MOAlgorithmStore {
  selectedIds: string[];
  toggleAlgorithm: (id: string) => void;
  selectAll: () => void;
  clearSelection: () => void;
}

function useMOAlgorithmStore(): MOAlgorithmStore {
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

  const toggleAlgorithm = (id: string) => {
    setSelectedIds(prev => 
      prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]
    );
  };

  const selectAll = () => {
    setSelectedIds(MO_ALGORITHMS.map(a => a.id));
  };

  const clearSelection = () => {
    setSelectedIds([]);
  };

  return { selectedIds, toggleAlgorithm, selectAll, clearSelection };
}

interface MOComparisonResult {
  algorithms: string[];
  problemName: string;
  results: Record<string, {
    paretoFront: number[][];
    hypervolume: number;
    igd: number;
    spacing: number;
    elapsedTime: number;
  }>;
}

export function MOComparisonPage() {
  const { selectedIds, toggleAlgorithm, selectAll, clearSelection } = useMOAlgorithmStore();

  const [selectedProblem, setSelectedProblem] = useState('ZDT1');
  const [populationSize, setPopulationSize] = useState(100);
  const [maxIterations, setMaxIterations] = useState(100);
  const [archiveSize, setArchiveSize] = useState(100);
  const [isRunning, setIsRunning] = useState(false);
  const [result, setResult] = useState<MOComparisonResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  const abortControllerRef = useRef<AbortController | null>(null);

  useEffect(() => {
    return () => {
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
        abortControllerRef.current = null;
      }
    };
  }, []);

  const handleRunComparison = async () => {
    if (selectedIds.length < 2) {
      message.warning('请至少选择2个多目标算法进行对比');
      return;
    }

    const problem = MO_PROBLEMS.find(p => p.id === selectedProblem);
    if (!problem) {
      message.error('未找到选中的测试问题');
      return;
    }

    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }
    abortControllerRef.current = new AbortController();

    setIsRunning(true);
    setError(null);
    setResult(null);

    try {
      message.info('多目标优化对比功能正在开发中...');
      
      const mockResult: MOComparisonResult = {
        algorithms: selectedIds,
        problemName: selectedProblem,
        results: {}
      };

      selectedIds.forEach(algId => {
        mockResult.results[algId] = {
          paretoFront: [],
          hypervolume: Math.random() * 0.5 + 0.5,
          igd: Math.random() * 0.1,
          spacing: Math.random() * 0.05,
          elapsedTime: Math.random() * 5 + 1
        };
      });

      setResult(mockResult);
      message.success('多目标优化对比完成！(模拟数据)');
    } catch (err) {
      if (err instanceof Error && err.name === 'AbortError') {
        return;
      }
      const errorMessage = err instanceof Error ? err.message : '优化执行失败';
      errorLogger.error('多目标算法对比失败', err);
      setError(errorMessage);
      message.error(errorMessage);
    } finally {
      setIsRunning(false);
      abortControllerRef.current = null;
    }
  };

  const columns = useMemo(() => [
    {
      title: '算法',
      dataIndex: 'algorithmId',
      key: 'algorithmId',
      render: (id: string) => (
        <Space>
          <span
            style={{
              width: 12,
              height: 12,
              borderRadius: '50%',
              backgroundColor: getMOAlgorithmColor(id),
              display: 'inline-block'
            }}
          />
          <Text strong>{id}</Text>
        </Space>
      ),
    },
    {
      title: 'Hypervolume',
      dataIndex: 'hypervolume',
      key: 'hypervolume',
      align: 'right' as const,
      render: (value: number) => toFixedSafe(value, 4),
    },
    {
      title: 'IGD',
      dataIndex: 'igd',
      key: 'igd',
      align: 'right' as const,
      render: (value: number) => toExponentialSafe(value, 4),
    },
    {
      title: 'Spacing',
      dataIndex: 'spacing',
      key: 'spacing',
      align: 'right' as const,
      render: (value: number) => toExponentialSafe(value, 4),
    },
    {
      title: '执行时间(s)',
      dataIndex: 'elapsedTime',
      key: 'elapsedTime',
      align: 'right' as const,
      render: (value: number) => toFixedSafe(value, 3),
    },
  ], []);

  const tableData = useMemo(() => {
    if (!result) return [];
    return result.algorithms.map((algId) => {
      const algResult = result.results[algId];
      return {
        key: algId,
        algorithmId: algId,
        hypervolume: algResult?.hypervolume,
        igd: algResult?.igd,
        spacing: algResult?.spacing,
        elapsedTime: algResult?.elapsedTime,
      };
    }) || [];
  }, [result]);

  const selectedProblemInfo = useMemo(() => {
    return MO_PROBLEMS.find(p => p.id === selectedProblem);
  }, [selectedProblem]);

  return (
    <div style={{ padding: 24 }}>
      <div style={{ marginBottom: 24 }}>
        <Title level={2} style={{ marginBottom: 8 }}>多目标优化对比</Title>
        <Text type="secondary">选择多个多目标优化算法进行Pareto前沿性能对比分析</Text>
      </div>

      <Row gutter={[24, 24]}>
        <Col xs={24} lg={16}>
          <Space direction="vertical" size="large" style={{ width: '100%' }}>
            <Card
              title={
                <Space>
                  <span>选择多目标算法</span>
                  <Tag color="purple">{selectedIds.length}/{MO_ALGORITHMS.length}</Tag>
                </Space>
              }
              extra={
                <Space>
                  <Button icon={<CheckOutlined />} onClick={selectAll}>
                    全选
                  </Button>
                  <Button icon={<CloseOutlined />} onClick={clearSelection}>
                    清空
                  </Button>
                </Space>
              }
            >
              <Space wrap>
                {MO_ALGORITHMS.map((alg) => (
                  <Tag
                    key={alg.id}
                    color={selectedIds.includes(alg.id) ? getMOAlgorithmColor(alg.id) : 'default'}
                    style={{
                      height: 40,
                      fontSize: 14,
                      padding: '8px 16px',
                      margin: '4px',
                      borderRadius: 6,
                      cursor: 'pointer',
                    }}
                    onClick={() => toggleAlgorithm(alg.id)}
                  >
                    {alg.name}
                  </Tag>
                ))}
              </Space>
            </Card>

            <Card title="对比结果" extra={result && <Text type="secondary">测试问题: {result.problemName}</Text>}>
              {error && (
                <ServerErrorIllustration size="sm" title="执行失败" description={error} />
              )}

              {isRunning && (
                <LoadingIllustration size="lg" title="正在执行多目标优化..." description="请稍候，这可能需要几秒到几分钟" />
              )}

              {!isRunning && !result && !error && (
                <EmptyDataIllustration size="lg" title="选择算法后运行对比" description="请在上方选择至少2个多目标算法，然后点击「运行对比」按钮" />
              )}

              {result && !isRunning && (
                <Space direction="vertical" size="large" style={{ width: '100%' }}>
                  <Table
                    columns={columns}
                    dataSource={tableData}
                    pagination={false}
                    scroll={{ y: 400 }}
                    size="middle"
                  />

                  <Card size="small" title={<Space><LineChartOutlined /><span>性能指标说明</span></Space>}>
                    <Row gutter={16}>
                      <Col span={6}>
                        <Statistic title="Hypervolume" value="越大越好" valueStyle={{ fontSize: 14 }} />
                        <Text type="secondary" style={{ fontSize: 12 }}>目标空间覆盖体积</Text>
                      </Col>
                      <Col span={6}>
                        <Statistic title="IGD" value="越小越好" valueStyle={{ fontSize: 14 }} />
                        <Text type="secondary" style={{ fontSize: 12 }}>逆世代距离</Text>
                      </Col>
                      <Col span={6}>
                        <Statistic title="Spacing" value="越小越好" valueStyle={{ fontSize: 14 }} />
                        <Text type="secondary" style={{ fontSize: 12 }}>解集均匀性</Text>
                      </Col>
                      <Col span={6}>
                        <Statistic title="Pareto解数" value="--" valueStyle={{ fontSize: 14 }} />
                        <Text type="secondary" style={{ fontSize: 12 }}>非支配解数量</Text>
                      </Col>
                    </Row>
                  </Card>
                </Space>
              )}
            </Card>
          </Space>
        </Col>

        <Col xs={24} lg={8}>
          <Space direction="vertical" size="large" style={{ width: '100%' }}>
            <Card title="测试问题">
              <Select
                value={selectedProblem}
                onChange={setSelectedProblem}
                style={{ width: '100%' }}
                options={[
                  { label: 'ZDT系列 (2目标)', options: MO_PROBLEMS.filter(p => p.type === 'ZDT').map(p => ({ label: `${p.id} - ${p.description}`, value: p.id })) },
                  { label: 'DTLZ系列 (可扩展)', options: MO_PROBLEMS.filter(p => p.type === 'DTLZ').map(p => ({ label: `${p.id} - ${p.description}`, value: p.id })) },
                ]}
              />
              {selectedProblemInfo && (
                <div style={{ marginTop: 16 }}>
                  <Space direction="vertical" size={8} style={{ width: '100%' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Text type="secondary">类型</Text>
                      <Text>{MO_PROBLEM_TYPE_NAMES[selectedProblemInfo.type]}</Text>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Text type="secondary">维度</Text>
                      <Text>{selectedProblemInfo.dimension}</Text>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Text type="secondary">目标数</Text>
                      <Text>{selectedProblemInfo.objCount}</Text>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Text type="secondary">描述</Text>
                      <Text>{selectedProblemInfo.description}</Text>
                    </div>
                  </Space>
                </div>
              )}
            </Card>

            <Card title="运行参数">
              <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                <div>
                  <Text type="secondary" style={{ marginBottom: 4, display: 'block' }}>种群大小</Text>
                  <InputNumber
                    value={populationSize}
                    onChange={(v) => setPopulationSize(v || 100)}
                    min={10}
                    max={1000}
                    style={{ width: '100%' }}
                  />
                </div>
                <div>
                  <Text type="secondary" style={{ marginBottom: 4, display: 'block' }}>最大迭代次数</Text>
                  <InputNumber
                    value={maxIterations}
                    onChange={(v) => setMaxIterations(v || 100)}
                    min={1}
                    max={10000}
                    style={{ width: '100%' }}
                  />
                </div>
                <div>
                  <Text type="secondary" style={{ marginBottom: 4, display: 'block' }}>存档大小</Text>
                  <InputNumber
                    value={archiveSize}
                    onChange={(v) => setArchiveSize(v || 100)}
                    min={10}
                    max={1000}
                    style={{ width: '100%' }}
                  />
                </div>
              </Space>
            </Card>

            <Space direction="vertical" size="middle" style={{ width: '100%' }}>
              <Button
                type="primary"
                icon={<PlayCircleOutlined />}
                onClick={handleRunComparison}
                disabled={isRunning || selectedIds.length < 2}
                loading={isRunning}
                block
                style={{ height: 56, fontSize: 16 }}
              >
                {isRunning ? '运行中...' : '运行对比'}
              </Button>
              <Button
                block
                icon={<DownloadOutlined />}
                disabled
                style={{ height: 48, fontSize: 14 }}
              >
                导出结果
              </Button>
            </Space>
          </Space>
        </Col>
      </Row>
    </div>
  );
}
