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
  Tabs,
  Switch,
} from 'antd';
import {
  PlayCircleOutlined,
  DownloadOutlined,
  CheckOutlined,
  CloseOutlined,
  LineChartOutlined,
  BarChartOutlined,
  TableOutlined,
} from '@ant-design/icons';
import { useAlgorithmStore } from '../../stores';
import { CATEGORY_NAMES, getAlgorithmColor } from '../../constants';
import { runComparison } from '../../api/endpoints';
import { EmptyDataIllustration, LoadingIllustration, ServerErrorIllustration } from '../../components/illustrations';
import { ConvergenceCurveChart, PerformanceBarChart } from '../../components/charts';
import type { ComparisonResult, AlgorithmConfig, ProblemDefinition } from '../../types';
import { toExponentialSafe, toFixedSafe, getLastElement } from '../../utils/arrayUtils';
import { errorLogger } from '../../utils/errorLogger';
import { useCatalogData } from '../../hooks/useCatalogData';

import type { ConvergenceCurveData, PerformanceData } from '../../components/charts';

const { Title, Text } = Typography;

export function ComparisonPage() {
  const { selectedIds, toggleAlgorithm, setSelectedIds, clearSelection } = useAlgorithmStore();
  const { algorithms, benchmarks } = useCatalogData();

  const [selectedBenchmark, setSelectedBenchmark] = useState('F1');
  const [populationSize, setPopulationSize] = useState(30);
  const [maxIterations, setMaxIterations] = useState(500);
  const [runs, setRuns] = useState(1);
  const [isRunning, setIsRunning] = useState(false);
  const [result, setResult] = useState<ComparisonResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('table');
  const [logScale, setLogScale] = useState(true);

  const abortControllerRef = useRef<AbortController | null>(null);

  useEffect(() => {
    return () => {
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
        abortControllerRef.current = null;
      }
    };
  }, []);

  const algorithmsByCategory = useMemo(() => {
    return algorithms.reduce((acc, alg) => {
      if (!acc[alg.category]) {
        acc[alg.category] = [];
      }
      acc[alg.category].push(alg);
      return acc;
    }, {} as Record<string, typeof algorithms>);
  }, [algorithms]);

  const selectAll = () => setSelectedIds(algorithms.map((algorithm) => algorithm.id));

  const handleRunComparison = async () => {
    if (selectedIds.length < 2) {
      message.warning('请至少选择2个算法进行对比');
      return;
    }

    const benchmark = benchmarks.find(f => f.id === selectedBenchmark);
    if (!benchmark) {
      message.error('未找到选中的基准函数');
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

  const selectedBenchmarkFunc = useMemo(() => {
    return benchmarks.find(f => f.id === selectedBenchmark);
  }, [benchmarks, selectedBenchmark]);

  const convergenceData = useMemo((): ConvergenceCurveData[] => {
    if (!result) return [];
    return result.algorithms.map((algId) => ({
      algorithmId: algId,
      data: result.results[algId]?.convergenceCurve || [],
    }));
  }, [result]);

  const performanceData = useMemo((): PerformanceData[] => {
    if (!result) return [];
    return result.algorithms.map((algId) => {
      const algResult = result.results[algId];
      return {
        algorithmId: algId,
        bestFitness: algResult?.bestFitness ?? 1,
        elapsedTime: algResult?.elapsedTime ?? 1,
      };
    });
  }, [result]);

  return (
    <div className="comparison-page">
      <div className="comparison-page__header">
        <Title level={2} className="comparison-page__title">单目标优化对比</Title>
        <Text type="secondary" className="comparison-page__description">选择多个单目标优化算法进行性能对比分析（如需多目标优化对比，请使用"多目标对比"功能）</Text>
      </div>

      <Row gutter={[24, 24]}>
        <Col xs={24} lg={16}>
          <Space direction="vertical" size="large" style={{ width: '100%' }}>
            <Card
              title={
                <Space>
                  <span>选择算法</span>
                  <Tag color="blue">{selectedIds.length}/{algorithms.length}</Tag>
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
                  <Tabs
                    activeKey={activeTab}
                    onChange={setActiveTab}
                    items={[
                      {
                        key: 'table',
                        label: <span><TableOutlined /> 结果表格</span>,
                      },
                      {
                        key: 'convergence',
                        label: <span><LineChartOutlined /> 收敛曲线</span>,
                      },
                      {
                        key: 'performance',
                        label: <span><BarChartOutlined /> 性能对比</span>,
                      },
                    ]}
                  />

                  {activeTab === 'table' && (
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
                  )}

                  {activeTab === 'convergence' && (
                    <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <Text type="secondary">收敛曲线对比展示各算法的优化过程</Text>
                        <Space>
                          <Text type="secondary">对数刻度:</Text>
                          <Switch checked={logScale} onChange={setLogScale} size="small" />
                        </Space>
                      </div>
                      <ConvergenceCurveChart
                        curves={convergenceData}
                        title="收敛曲线对比"
                        height={450}
                        showLegend
                        logScale={logScale}
                      />
                      <Card size="small" title="收敛数据摘要">
                        <Row gutter={[8, 8]}>
                          {result.algorithms.map((algId) => {
                            const algResult = result.results[algId];
                            const convergence = algResult?.convergenceCurve || [];
                            return (
                              <Col xs={12} sm={8} md={6} key={algId}>
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

                  {activeTab === 'performance' && (
                    <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                      <Text type="secondary">性能对比柱状图展示各算法的关键指标对比</Text>
                      <PerformanceBarChart
                        data={performanceData}
                        title="最优适应度对比"
                        metric="bestFitness"
                        height={350}
                        showStdDev={false}
                      />
                      <PerformanceBarChart
                        data={performanceData}
                        title="执行时间对比"
                        metric="elapsedTime"
                        height={300}
                        showStdDev={false}
                      />
                    </Space>
                  )}
                </Space>
              )}
            </Card>
          </Space>
        </Col>

        <Col xs={24} lg={8}>
          <Space direction="vertical" size="large" style={{ width: '100%' }}>
            <Card title="基准函数">
              <Select
                value={selectedBenchmark}
                onChange={setSelectedBenchmark}
                style={{ width: '100%' }}
                options={benchmarks.map(func => ({
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
