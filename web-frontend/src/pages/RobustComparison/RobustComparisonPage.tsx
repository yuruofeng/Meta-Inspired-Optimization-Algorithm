import { useState, useMemo, useRef, useEffect } from 'react';
import {
  Card,
  Row,
  Col,
  Typography,
  InputNumber,
  Button,
  Space,
  Tag,
  Table,
  Badge,
  message,
  Tabs,
  Descriptions,
  Tooltip,
  Divider,
  Switch,
} from 'antd';
import {
  PlayCircleOutlined,
  DownloadOutlined,
  CheckOutlined,
  CloseOutlined,
  LineChartOutlined,
  InfoCircleOutlined,
  ExperimentOutlined,
  BarChartOutlined,
  TableOutlined,
} from '@ant-design/icons';
import { useAlgorithmStore } from '../../stores';
import { ALGORITHMS, CATEGORY_NAMES, getAlgorithmColor } from '../../constants';
import {
  ROBUST_BENCHMARK_FUNCTIONS,
  ROBUST_TYPE_NAMES,
  ROBUST_TYPE_DESCRIPTIONS,
} from '../../constants/robustBenchmarks';
import { runComparison } from '../../api/endpoints';
import { EmptyDataIllustration, LoadingIllustration, ServerErrorIllustration } from '../../components/illustrations';
import { ConvergenceCurveChart, PerformanceBarChart } from '../../components/charts';
import type { ConvergenceCurveData, PerformanceData } from '../../components/charts';
import type { ComparisonResult, AlgorithmConfig, ProblemDefinition, RobustBenchmarkType } from '../../types';
import { toExponentialSafe, toFixedSafe, getLastElement } from '../../utils/arrayUtils';
import { errorLogger } from '../../utils/errorLogger';

const { Title, Text, Paragraph } = Typography;

export function RobustComparisonPage() {
  const { selectedIds, toggleAlgorithm, selectAll, clearSelection } = useAlgorithmStore();

  const [selectedBenchmark, setSelectedBenchmark] = useState('R1');
  const [populationSize, setPopulationSize] = useState(30);
  const [maxIterations, setMaxIterations] = useState(500);
  const [runs, setRuns] = useState(1);
  const [isRunning, setIsRunning] = useState(false);
  const [result, setResult] = useState<ComparisonResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [activeType, setActiveType] = useState<RobustBenchmarkType>('Biased');
  const [activeResultTab, setActiveResultTab] = useState('table');
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
    return ALGORITHMS.reduce((acc, alg) => {
      if (!acc[alg.category]) {
        acc[alg.category] = [];
      }
      acc[alg.category].push(alg);
      return acc;
    }, {} as Record<string, typeof ALGORITHMS>);
  }, []);

  const robustFunctionsByType = useMemo(() => {
    return ROBUST_BENCHMARK_FUNCTIONS.reduce((acc, func) => {
      if (!acc[func.type]) {
        acc[func.type] = [];
      }
      acc[func.type].push(func);
      return acc;
    }, {} as Record<RobustBenchmarkType, typeof ROBUST_BENCHMARK_FUNCTIONS>);
  }, []);

  const handleRunComparison = async () => {
    if (selectedIds.length < 2) {
      message.warning('Please select at least 2 algorithms for comparison');
      return;
    }

    const benchmark = ROBUST_BENCHMARK_FUNCTIONS.find(f => f.id === selectedBenchmark);
    if (!benchmark) {
      message.error('Selected benchmark function not found');
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
      message.success('Robust benchmark comparison completed!');
    } catch (err) {
      if (err instanceof Error && err.name === 'AbortError') {
        console.log('[RobustComparisonPage] Request cancelled');
        return;
      }
      const errorMessage = err instanceof Error ? err.message : 'Optimization failed, please check backend service';
      errorLogger.error('Robust benchmark comparison failed', err);
      setError(errorMessage);
      message.error(errorMessage);
    } finally {
      setIsRunning(false);
      abortControllerRef.current = null;
    }
  };

  const columns = useMemo(() => [
    {
      title: 'Algorithm',
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
      title: 'Best Fitness',
      dataIndex: 'bestFitness',
      key: 'bestFitness',
      align: 'right' as const,
      render: (value: number) => toExponentialSafe(value, 6),
    },
    {
      title: 'Time (s)',
      dataIndex: 'elapsedTime',
      key: 'elapsedTime',
      align: 'right' as const,
      render: (value: number) => toFixedSafe(value, 3),
    },
    {
      title: 'Rank',
      dataIndex: 'ranking',
      key: 'ranking',
      align: 'right' as const,
      render: (ranking: number) => (
        <Badge
          count={ranking}
          style={{
            backgroundColor: ranking === 1 ? '#faad14' : ranking === 2 ? '#8c8c8c' : '#d46b08'
          }}
        />
      ),
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
    return ROBUST_BENCHMARK_FUNCTIONS.find(f => f.id === selectedBenchmark);
  }, [selectedBenchmark]);

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

  const typeTabs = useMemo(() => {
    return (['Biased', 'Deceptive', 'Multimodal', 'Flat'] as RobustBenchmarkType[]).map(type => ({
      key: type,
      label: (
        <Space>
          <span>{ROBUST_TYPE_NAMES[type]}</span>
          <Tag color="blue">{robustFunctionsByType[type]?.length || 0}</Tag>
        </Space>
      ),
    }));
  }, [robustFunctionsByType]);

  return (
    <div style={{ padding: 24 }}>
      <div style={{ marginBottom: 24 }}>
        <Title level={2} style={{ marginBottom: 8 }}>
          <ExperimentOutlined style={{ marginRight: 8 }} />
          Robust Benchmark Comparison
        </Title>
        <Paragraph type="secondary">
          Test algorithm robustness using benchmark functions with obstacles such as bias, deceptiveness, multimodality, and flat regions.
        </Paragraph>
      </div>

      <Row gutter={[24, 24]}>
        <Col xs={24} lg={16}>
          <Space direction="vertical" size="large" style={{ width: '100%' }}>
            <Card
              title={
                <Space>
                  <span>Select Algorithms</span>
                  <Tag color="blue">{selectedIds.length}/{ALGORITHMS.length}</Tag>
                </Space>
              }
              extra={
                <Space>
                  <Button
                    icon={<CheckOutlined />}
                    onClick={selectAll}
                    style={{ height: 40, fontSize: 14 }}
                  >
                    Select All
                  </Button>
                  <Button
                    icon={<CloseOutlined />}
                    onClick={clearSelection}
                    style={{ height: 40, fontSize: 14 }}
                  >
                    Clear
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
                          style={{
                            height: 36,
                            fontSize: 14,
                            padding: '6px 12px',
                            margin: '4px',
                            borderRadius: 6,
                            cursor: 'pointer',
                            display: 'inline-flex',
                            alignItems: 'center',
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

            <Card title="Comparison Results" extra={result && <Text type="secondary">Function: {result.functionName}</Text>}>
              {error && (
                <ServerErrorIllustration
                  size="sm"
                  title="Execution Failed"
                  description={error}
                />
              )}

              {isRunning && (
                <LoadingIllustration
                  size="lg"
                  title="Running Optimization..."
                  description="Please wait, this may take a few seconds to minutes"
                />
              )}

              {!isRunning && !result && !error && (
                <EmptyDataIllustration
                  size="lg"
                  title="Select Algorithms and Run Comparison"
                  description="Please select at least 2 algorithms above, then click the 'Run Comparison' button"
                />
              )}

              {result && !isRunning && (
                <Space direction="vertical" size="large" style={{ width: '100%' }}>
                  <Tabs
                    activeKey={activeResultTab}
                    onChange={setActiveResultTab}
                    items={[
                      {
                        key: 'table',
                        label: <span><TableOutlined /> Results Table</span>,
                      },
                      {
                        key: 'convergence',
                        label: <span><LineChartOutlined /> Convergence</span>,
                      },
                      {
                        key: 'performance',
                        label: <span><BarChartOutlined /> Performance</span>,
                      },
                    ]}
                  />

                  {activeResultTab === 'table' && (
                    <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                      <Table
                        columns={columns}
                        dataSource={tableData}
                        pagination={{
                          pageSize: 10,
                          showSizeChanger: true,
                          showQuickJumper: true,
                          showTotal: (total) => `Total ${total} items`,
                          pageSizeOptions: ['5', '10', '20', '50'],
                        }}
                        scroll={{ y: 400 }}
                        size="middle"
                      />
                      <Card size="small" title={<Space><LineChartOutlined /><span>Convergence Summary</span></Space>}>
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
                                      Iterations: {convergence.length}
                                    </Text>
                                    <Text type="secondary" style={{ fontSize: 11 }}>
                                      Final: {toExponentialSafe(getLastElement(convergence), 4)}
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

                  {activeResultTab === 'convergence' && (
                    <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <Text type="secondary">Convergence curves show the optimization process of each algorithm</Text>
                        <Space>
                          <Text type="secondary">Log Scale:</Text>
                          <Switch checked={logScale} onChange={setLogScale} size="small" />
                        </Space>
                      </div>
                      <ConvergenceCurveChart
                        curves={convergenceData}
                        title="Convergence Curve Comparison"
                        height={450}
                        showLegend
                        logScale={logScale}
                      />
                    </Space>
                  )}

                  {activeResultTab === 'performance' && (
                    <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                      <Text type="secondary">Performance comparison charts show key metrics across algorithms</Text>
                      <PerformanceBarChart
                        data={performanceData}
                        title="Best Fitness Comparison"
                        metric="bestFitness"
                        height={350}
                        showStdDev
                      />
                      <PerformanceBarChart
                        data={performanceData}
                        title="Execution Time Comparison"
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
            <Card title="Robust Benchmark Functions">
              <Tabs
                activeKey={activeType}
                onChange={(key) => {
                  setActiveType(key as RobustBenchmarkType);
                  const funcs = robustFunctionsByType[key as RobustBenchmarkType];
                  if (funcs && funcs.length > 0) {
                    setSelectedBenchmark(funcs[0].id);
                  }
                }}
                items={typeTabs}
              />
              <Divider style={{ margin: '12px 0' }} />
              <Space direction="vertical" size="small" style={{ width: '100%' }}>
                {robustFunctionsByType[activeType]?.map((func) => (
                  <Card
                    key={func.id}
                    size="small"
                    hoverable
                    style={{
                      backgroundColor: selectedBenchmark === func.id ? '#e6f4ff' : undefined,
                      borderColor: selectedBenchmark === func.id ? '#1677ff' : undefined,
                    }}
                    onClick={() => setSelectedBenchmark(func.id)}
                  >
                    <Space direction="vertical" size={4} style={{ width: '100%' }}>
                      <Space>
                        <Text strong>{func.id}</Text>
                        <Text type="secondary">{func.name}</Text>
                      </Space>
                      <Text type="secondary" style={{ fontSize: 12 }}>
                        {func.description}
                      </Text>
                    </Space>
                  </Card>
                ))}
              </Space>
            </Card>

            {selectedBenchmarkFunc && (
              <Card title="Function Details" size="small">
                <Descriptions column={1} size="small">
                  <Descriptions.Item label="ID">{selectedBenchmarkFunc.id}</Descriptions.Item>
                  <Descriptions.Item label="Name">{selectedBenchmarkFunc.name}</Descriptions.Item>
                  <Descriptions.Item label="Type">
                    <Space>
                      {ROBUST_TYPE_NAMES[selectedBenchmarkFunc.type]}
                      <Tooltip title={ROBUST_TYPE_DESCRIPTIONS[selectedBenchmarkFunc.type]}>
                        <InfoCircleOutlined style={{ color: '#1677ff' }} />
                      </Tooltip>
                    </Space>
                  </Descriptions.Item>
                  <Descriptions.Item label="Dimension">{selectedBenchmarkFunc.dimension}</Descriptions.Item>
                  <Descriptions.Item label="Bounds">
                    [{selectedBenchmarkFunc.lowerBound}, {selectedBenchmarkFunc.upperBound}]
                  </Descriptions.Item>
                  <Descriptions.Item label="Delta (Tolerance)">
                    {selectedBenchmarkFunc.delta}
                  </Descriptions.Item>
                </Descriptions>
              </Card>
            )}

            <Card title="Run Parameters">
              <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                <div>
                  <Text type="secondary" style={{ marginBottom: 4, display: 'block' }}>Population Size</Text>
                  <InputNumber
                    value={populationSize}
                    onChange={(v) => setPopulationSize(v || 30)}
                    min={5}
                    max={1000}
                    style={{ width: '100%' }}
                  />
                </div>
                <div>
                  <Text type="secondary" style={{ marginBottom: 4, display: 'block' }}>Max Iterations</Text>
                  <InputNumber
                    value={maxIterations}
                    onChange={(v) => setMaxIterations(v || 500)}
                    min={1}
                    max={10000}
                    style={{ width: '100%' }}
                  />
                </div>
                <div>
                  <Text type="secondary" style={{ marginBottom: 4, display: 'block' }}>Independent Runs</Text>
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
                style={{ height: 56, fontSize: 16 }}
              >
                {isRunning ? 'Running...' : 'Run Comparison'}
              </Button>
              <Button
                block
                icon={<DownloadOutlined />}
                disabled
                style={{ height: 56, fontSize: 16 }}
              >
                Export Results
              </Button>
            </Space>
          </Space>
        </Col>
      </Row>
    </div>
  );
}
