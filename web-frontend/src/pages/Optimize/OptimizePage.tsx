import { useState, useRef, useEffect } from 'react';
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
  Statistic,
  Descriptions,
} from 'antd';
import {
  PlayCircleOutlined,
  ClockCircleOutlined,
  AimOutlined,
  LineChartOutlined,
  SettingOutlined,
} from '@ant-design/icons';
import { ALGORITHMS, BENCHMARK_FUNCTIONS, CATEGORY_NAMES } from '../../constants';
import { runOptimization } from '../../api/endpoints';
import { EmptyDataIllustration, LoadingIllustration, ServerErrorIllustration } from '../../components/illustrations';
import type { OptimizationResult, AlgorithmConfig, ProblemDefinition } from '../../types';
import { toExponentialSafe, toFixedSafe } from '../../utils/arrayUtils';
import { errorLogger } from '../../utils/errorLogger';

const { Title, Text } = Typography;

export function OptimizePage() {
  const [selectedAlgorithm, setSelectedAlgorithm] = useState('GWO');
  const [selectedBenchmark, setSelectedBenchmark] = useState('F1');
  const [populationSize, setPopulationSize] = useState(30);
  const [maxIterations, setMaxIterations] = useState(500);
  const [isRunning, setIsRunning] = useState(false);
  const [result, setResult] = useState<OptimizationResult | null>(null);
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

  const handleRunOptimization = async () => {
    const benchmark = BENCHMARK_FUNCTIONS.find(f => f.id === selectedBenchmark);
    if (!benchmark) {
      setError('未找到选中的基准函数');
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

      const response = await runOptimization({
        algorithm: selectedAlgorithm,
        problem,
        config
      }, abortControllerRef.current.signal);

      setResult(response);
    } catch (err) {
      // 如果是取消导致的错误，不显示消息
      if (err instanceof Error && err.name === 'AbortError') {
        console.log('[OptimizePage] 请求已取消');
        return;
      }
      const errorMessage = err instanceof Error ? err.message : '优化执行失败，请检查后端服务是否正常运行';
      errorLogger.error('单次优化失败', err);
      setError(errorMessage);
    } finally {
      setIsRunning(false);
      abortControllerRef.current = null;
    }
  };

  const selectedAlgInfo = ALGORITHMS.find(a => a.id === selectedAlgorithm);
  const selectedBenchmarkInfo = BENCHMARK_FUNCTIONS.find(f => f.id === selectedBenchmark);

  return (
    <div style={{ padding: 24 }}>
      <div style={{ marginBottom: 24 }}>
        <Title level={2} style={{ marginBottom: 8 }}>单次优化</Title>
        <Text type="secondary">运行单个算法并查看详细结果</Text>
      </div>

      <Row gutter={[24, 24]}>
        <Col xs={24} lg={16}>
          <Card title="优化结果">
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
                description="请稍候，这可能需要几秒钟"
              />
            )}

            {!isRunning && !result && !error && (
              <EmptyDataIllustration
                size="lg"
                title="准备就绪"
                description="配置参数后点击「开始优化」查看结果"
              />
            )}

            {result && !isRunning && (
              <Space direction="vertical" size="large" style={{ width: '100%' }}>
                {/* 统计指标 */}
                <Row gutter={[16, 16]}>
                  <Col xs={12} sm={6}>
                    <Card size="small">
                      <Statistic
                        title="最优适应度"
                        value={toExponentialSafe(result.bestFitness, 6)}
                        prefix={<AimOutlined style={{ color: '#1677ff' }} />}
                      />
                    </Card>
                  </Col>
                  <Col xs={12} sm={6}>
                    <Card size="small">
                      <Statistic
                        title="执行时间"
                        value={toFixedSafe(result.elapsedTime, 3)}
                        suffix="s"
                        prefix={<ClockCircleOutlined style={{ color: '#52c41a' }} />}
                      />
                    </Card>
                  </Col>
                  <Col xs={12} sm={6}>
                    <Card size="small">
                      <Statistic
                        title="迭代次数"
                        value={result.convergenceCurve.length}
                        prefix={<LineChartOutlined style={{ color: '#722ed1' }} />}
                      />
                    </Card>
                  </Col>
                  <Col xs={12} sm={6}>
                    <Card size="small">
                      <Statistic
                        title="函数评估"
                        value={result.totalEvaluations.toLocaleString()}
                      />
                    </Card>
                  </Col>
                </Row>

                {/* 收敛曲线采样 */}
                <Card size="small" title={<Space><LineChartOutlined /><span>收敛曲线</span></Space>}>
                  <Row gutter={[8, 8]}>
                    {result.convergenceCurve.slice(0, 10).map((value, idx) => (
                      <Col xs={12} sm={8} md={4} key={idx}>
                        <Card size="small" styles={{ body: { padding: 8 } }}>
                          <Text type="secondary" style={{ fontSize: 11 }}>
                            迭代 {Math.floor(idx * result.convergenceCurve.length / 10)}
                          </Text>
                          <br />
                          <Text strong style={{ fontSize: 12, fontFamily: 'monospace' }}>
                            {toExponentialSafe(value, 4)}
                          </Text>
                        </Card>
                      </Col>
                    ))}
                  </Row>
                  <Text type="secondary" style={{ fontSize: 11, marginTop: 8, display: 'block' }}>
                    显示前10个采样点（共{result.convergenceCurve.length}个点）
                  </Text>
                </Card>

                {/* 最佳解向量 */}
                <Card size="small" title="最佳解向量">
                  <div style={{ maxHeight: 200, overflow: 'auto' }}>
                    <Space wrap size={[4, 4]}>
                      {result.bestSolution.map((v, i) => (
                        <Tag key={i} style={{ fontFamily: 'monospace', margin: 0 }}>
                          {toFixedSafe(v, 4)}
                        </Tag>
                      ))}
                    </Space>
                  </div>
                  <Text type="secondary" style={{ fontSize: 11, marginTop: 8, display: 'block' }}>
                    维度: {result.bestSolution.length}
                  </Text>
                </Card>

                {/* 运行信息 */}
                {result.metadata && (
                  <Descriptions title="运行信息" size="small" bordered column={2}>
                    <Descriptions.Item label="算法">{result.metadata.algorithm}</Descriptions.Item>
                    <Descriptions.Item label="版本">{result.metadata.version}</Descriptions.Item>
                    <Descriptions.Item label="种群大小">{result.metadata.config?.populationSize}</Descriptions.Item>
                    <Descriptions.Item label="最大迭代">{result.metadata.config?.maxIterations}</Descriptions.Item>
                  </Descriptions>
                )}
              </Space>
            )}
          </Card>
        </Col>

        <Col xs={24} lg={8}>
          <Space direction="vertical" size="large" style={{ width: '100%' }}>
            {/* 选择算法 */}
            <Card title="选择算法">
              <Select
                value={selectedAlgorithm}
                onChange={setSelectedAlgorithm}
                style={{ width: '100%' }}
                options={ALGORITHMS.map(alg => ({
                  label: `${alg.name} - ${alg.fullName}`,
                  value: alg.id,
                }))}
              />
              {selectedAlgInfo && (
                <div style={{ marginTop: 16 }}>
                  <Space direction="vertical" size={8} style={{ width: '100%' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Text type="secondary">类别</Text>
                      <Tag color="blue">{CATEGORY_NAMES[selectedAlgInfo.category as keyof typeof CATEGORY_NAMES] || selectedAlgInfo.category}</Tag>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Text type="secondary">版本</Text>
                      <Text>{selectedAlgInfo.version}</Text>
                    </div>
                    <Text type="secondary" style={{ fontSize: 12 }}>
                      {selectedAlgInfo.description}
                    </Text>
                  </Space>
                </div>
              )}
            </Card>

            {/* 基准函数 */}
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
              {selectedBenchmarkInfo && (
                <div style={{ marginTop: 16 }}>
                  <Space direction="vertical" size={8} style={{ width: '100%' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Text type="secondary">类型</Text>
                      <Text>{selectedBenchmarkInfo.type}</Text>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Text type="secondary">维度</Text>
                      <Text>{selectedBenchmarkInfo.dimension}</Text>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Text type="secondary">最优值</Text>
                      <Text>{selectedBenchmarkInfo.optimalValue}</Text>
                    </div>
                  </Space>
                </div>
              )}
            </Card>

            {/* 运行参数 */}
            <Card title={<Space><SettingOutlined /><span>运行参数</span></Space>}>
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
              </Space>
            </Card>

            {/* 操作按钮 */}
            <Button
              type="primary"
              size="large"
              block
              icon={<PlayCircleOutlined />}
              onClick={handleRunOptimization}
              disabled={isRunning}
              loading={isRunning}
            >
              {isRunning ? '运行中...' : '开始优化'}
            </Button>
          </Space>
        </Col>
      </Row>
    </div>
  );
}
