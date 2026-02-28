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
  Badge,
  message,
} from 'antd';
import {
  PlayCircleOutlined,
  DownloadOutlined,
  CheckOutlined,
  CloseOutlined,
  LineChartOutlined,
} from '@ant-design/icons';
import { useAlgorithmStore } from '../../stores';
import { ALGORITHMS, BENCHMARK_FUNCTIONS, CATEGORY_NAMES, getAlgorithmColor } from '../../constants';
import { runComparison } from '../../api/endpoints';
import { EmptyDataIllustration, LoadingIllustration, ServerErrorIllustration } from '../../components/illustrations';
import type { ComparisonResult, AlgorithmConfig, ProblemDefinition } from '../../types';
import { toExponentialSafe, toFixedSafe, getLastElement } from '../../utils/arrayUtils';
import { errorLogger } from '../../utils/errorLogger';

const { Title, Text } = Typography;

export function ComparisonPage() {
  const { selectedIds, toggleAlgorithm, selectAll, clearSelection } = useAlgorithmStore();

  const [selectedBenchmark, setSelectedBenchmark] = useState('F1');
  const [populationSize, setPopulationSize] = useState(30);
  const [maxIterations, setMaxIterations] = useState(500);
  const [runs, setRuns] = useState(1);
  const [isRunning, setIsRunning] = useState(false);
  const [result, setResult] = useState<ComparisonResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  // 请求取消控制器
  const abortControllerRef = useRef<AbortController | null>(null);

  // 组件卸载时取消所有未完成的请求
  useEffect(() => {
    return () => {
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
        abortControllerRef.current = null;
      }
    };
  }, []);

  // 算法分类数据（静态数据，使用useMemo避免重复计算）
  const algorithmsByCategory = useMemo(() => {
    return ALGORITHMS.reduce((acc, alg) => {
      if (!acc[alg.category]) {
        acc[alg.category] = [];
      }
      acc[alg.category].push(alg);
      return acc;
    }, {} as Record<string, typeof ALGORITHMS>);
  }, []);

  const handleRunComparison = async () => {
    if (selectedIds.length < 2) {
      message.warning('请至少选择2个算法进行对比');
      return;
    }

    const benchmark = BENCHMARK_FUNCTIONS.find(f => f.id === selectedBenchmark);
    if (!benchmark) {
      message.error('未找到选中的基准函数');
      return;
    }

    // 取消之前的请求
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }
    // 创建新的取消控制器
    abortControllerRef.current = new AbortController();

    setIsRunning(true);
    setError(null);
    setResult(null);

    try {
      const config: AlgorithmConfig = {
        populationSize,
        maxIterations,
        verbose: false
      };

      const problem: ProblemDefinition = {
        id: selectedBenchmark,
        type: 'benchmark',
        dimension: benchmark.dimension,
        lowerBound: benchmark.lowerBound,
        upperBound: benchmark.upperBound
      };

      const response = await runComparison({
        algorithms: selectedIds,
        problem,
        config,
        runsPerAlgorithm: runs
      }, abortControllerRef.current.signal);

      setResult(response);
      message.success('算法对比完成！');
    } catch (err) {
      // 如果是取消导致的错误，不显示消息
      if (err instanceof Error && err.name === 'AbortError') {
        console.log('[ComparisonPage] 请求已取消');
        return;
      }
      const errorMessage = err instanceof Error ? err.message : '优化执行失败，请检查后端服务是否正常运行';
      errorLogger.error('算法对比失败', err);
      setError(errorMessage);
      message.error(errorMessage);
    } finally {
      setIsRunning(false);
      abortControllerRef.current = null;
    }
  };

  // 表格列定义（不会变化）
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
              backgroundColor: getAlgorithmColor(id),
              display: 'inline-block'
            }}
          />
          <Text strong>{id}</Text>
        </Space>
      ),
    },
    {
      title: '最优适应度',
      dataIndex: 'bestFitness',
      key: 'bestFitness',
      align: 'right' as const,
      render: (value: number) => toExponentialSafe(value, 6),
    },
    {
      title: '执行时间(s)',
      dataIndex: 'elapsedTime',
      key: 'elapsedTime',
      align: 'right' as const,
      render: (value: number) => toFixedSafe(value, 3),
    },
    {
      title: '排名',
      dataIndex: 'ranking',
      key: 'ranking',
      align: 'right' as const,
      render: (ranking: number) => {
        return (
          <Badge
            count={ranking}
            style={{
              backgroundColor: ranking === 1 ? '#faad14' : ranking === 2 ? '#8c8c8c' : '#d46b08'
            }}
          />
        );
      },
    },
  ], []);

  // 表格数据转换（仅在result变化时重新计算）
  const tableData = useMemo(() => {
    if (!result) return [];
    return result.algorithms.map((algId) => {
      const algResult = result.results[algId];
      const ranking = result.statistics.rankings[algId];
      return {
        key: algId,
        algorithmId: algId,
        bestFitness: algResult?.bestFitness,
        elapsedTime: algResult?.elapsedTime,
        ranking,
      };
    }) || [];
  }, [result]);

  // 选中的基准函数（使用useMemo优化）
  const selectedBenchmarkFunc = useMemo(() => {
    return BENCHMARK_FUNCTIONS.find(f => f.id === selectedBenchmark);
  }, [selectedBenchmark]);

  return (
    <div style={{ padding: 24 }}>
      <div style={{ marginBottom: 24 }}>
        <Title level={2} style={{ marginBottom: 8 }}>单目标优化对比</Title>
        <Text type="secondary">选择多个单目标优化算法进行性能对比分析（如需多目标优化对比，请使用"多目标对比"功能）</Text>
      </div>

      <Row gutter={[24, 24]}>
        <Col xs={24} lg={16}>
          <Space direction="vertical" size="large" style={{ width: '100%' }}>
            {/* 算法选择 */}
            <Card
              title={
                <Space>
                  <span>选择算法</span>
                  <Tag color="blue">{selectedIds.length}/{ALGORITHMS.length}</Tag>
                </Space>
              }
              extra={
                <Space>
                  <Button
                    icon={<CheckOutlined />}
                    onClick={selectAll}
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
                    onClick={clearSelection}
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
              }
            >
              <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                {Object.entries(algorithmsByCategory).map(([category, algorithms]) => (
                  <div key={category}>
                    <Text type="secondary" style={{ marginBottom: 8, display: 'block' }}>
                      {CATEGORY_NAMES[category as keyof typeof CATEGORY_NAMES] || category}
                    </Text>
                    <Space wrap>
                      {algorithms.map((alg) => (
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
                          onClick={() => toggleAlgorithm(alg.id)}
                        >
                          {alg.name}
                        </Tag>
                      ))}
                    </Space>
                  </div>
                ))}
              </Space>
            </Card>

            {/* 对比结果 */}
            <Card title="对比结果" extra={result && <Text type="secondary">基准函数: {result.functionName}</Text>}>
              {error && (
                <ServerErrorIllustration
                  size="sm"
                  title="执行失败"
                  description={error}
                />
              )}

              {isRunning && (
                <LoadingIllustration
                  size="lg"
                  title="正在执行优化..."
                  description="请稍候，这可能需要几秒到几分钟"
                />
              )}

              {!isRunning && !result && !error && (
                <EmptyDataIllustration
                  size="lg"
                  title="选择算法后运行对比"
                  description="请在上方选择至少2个算法，然后点击「运行对比」按钮"
                />
              )}

              {result && !isRunning && (
                <Space direction="vertical" size="large" style={{ width: '100%' }}>
                  <Table
                    columns={columns}
                    dataSource={tableData}
                    pagination={{
                      pageSize: 10,
                      showSizeChanger: true,
                      showQuickJumper: true,
                      showTotal: (total) => `共 ${total} 条`,
                      pageSizeOptions: ['5', '10', '20', '50'],
                    }}
                    scroll={{ y: 400 }}
                    size="middle"
                  />

                  <Card size="small" title={<Space><LineChartOutlined /><span>收敛曲线数据</span></Space>}>
                    <Row gutter={[8, 8]}>
                      {result.algorithms.map((algId) => {
                        const algResult = result.results[algId];
                        const convergence = algResult?.convergenceCurve || [];
                        return (
                          <Col xs={12} sm={8} key={algId}>
                            <Card size="small" styles={{ body: { padding: 8 } }}>
                              <Space direction="vertical" size={4} style={{ width: '100%' }}>
                                <Space>
                                  <span
                                    style={{
                                      width: 8,
                                      height: 8,
                                      borderRadius: '50%',
                                      backgroundColor: getAlgorithmColor(algId),
                                      display: 'inline-block'
                                    }}
                                  />
                                  <Text strong style={{ fontSize: 12 }}>{algId}</Text>
                                </Space>
                                <Text type="secondary" style={{ fontSize: 11 }}>
                                  迭代: {convergence.length}
                                </Text>
                                <Text type="secondary" style={{ fontSize: 11 }}>
                                  最终: {toExponentialSafe(getLastElement(convergence), 4)}
                                </Text>
                              </Space>
                            </Card>
                          </Col>
                        );
                      })}
                    </Row>
                  </Card>
                </Space>
              )}
            </Card>
          </Space>
        </Col>

        <Col xs={24} lg={8}>
          <Space direction="vertical" size="large" style={{ width: '100%' }}>
            {/* 基准函数选择 */}
            <Card title="基准函数">
              <Select
                value={selectedBenchmark}
                onChange={setSelectedBenchmark}
                style={{ width: '100%' }}
                options={BENCHMARK_FUNCTIONS.map(func => ({
                  label: `${func.id} - ${func.name}`,
                  value: func.id,
                }))}
              />
              {selectedBenchmarkFunc && (
                <div style={{ marginTop: 16 }}>
                  <Space direction="vertical" size={8} style={{ width: '100%' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Text type="secondary">类型</Text>
                      <Text>{selectedBenchmarkFunc.type}</Text>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Text type="secondary">维度</Text>
                      <Text>{selectedBenchmarkFunc.dimension}</Text>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Text type="secondary">最优值</Text>
                      <Text>{selectedBenchmarkFunc.optimalValue}</Text>
                    </div>
                  </Space>
                </div>
              )}
            </Card>

            {/* 运行参数 */}
            <Card title="运行参数">
              <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                <div>
                  <Text type="secondary" style={{ marginBottom: 4, display: 'block' }}>种群大小</Text>
                  <InputNumber
                    value={populationSize}
                    onChange={(v) => setPopulationSize(v || 30)}
                    min={5}
                    max={1000}
                    style={{ width: '100%' }}
                  />
                </div>
                <div>
                  <Text type="secondary" style={{ marginBottom: 4, display: 'block' }}>最大迭代次数</Text>
                  <InputNumber
                    value={maxIterations}
                    onChange={(v) => setMaxIterations(v || 500)}
                    min={1}
                    max={10000}
                    style={{ width: '100%' }}
                  />
                </div>
                <div>
                  <Text type="secondary" style={{ marginBottom: 4, display: 'block' }}>独立运行次数</Text>
                  <InputNumber
                    value={runs}
                    onChange={(v) => setRuns(v || 1)}
                    min={1}
                    max={100}
                    style={{ width: '100%' }}
                  />
                </div>
              </Space>
            </Card>

            {/* 操作按钮 */}
            <Space direction="vertical" size="middle" style={{ width: '100%' }}>
              <Button
                type="primary"
                icon={<PlayCircleOutlined />}
                onClick={handleRunComparison}
                disabled={isRunning || selectedIds.length < 2}
                loading={isRunning}
                block
                className="algorithm-btn-primary-enhanced"
                style={{
                  height: 72,
                  fontSize: 18,
                  padding: '16px 28px',
                  borderRadius: 10,
                }}
                aria-busy={isRunning}
                aria-label={isRunning ? '运行对比中' : '开始运行对比'}
              >
                {isRunning ? '运行中...' : '运行对比'}
              </Button>
              <Button
                block
                icon={<DownloadOutlined />}
                disabled
                className="algorithm-btn-enhanced"
                style={{
                  height: 72,
                  fontSize: 18,
                  padding: '16px 28px',
                  borderRadius: 10,
                }}
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
