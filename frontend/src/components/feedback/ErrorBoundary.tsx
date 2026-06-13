/**
 * React 错误边界组件
 * 捕获子组件的 JavaScript 错误，防止整个应用崩溃
 */

import { Component, type ReactNode, type ErrorInfo } from 'react';
import { Result, Button, Typography } from 'antd';
import { BugOutlined, ReloadOutlined, HomeOutlined } from '@ant-design/icons';

const { Paragraph } = Typography;

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null,
    };
  }

  static getDerivedStateFromError(error: Error): Partial<State> {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    this.setState({ errorInfo });
    // 记录错误到控制台
    console.error('[ErrorBoundary] 捕获到错误:', error);
    console.error('[ErrorBoundary] 组件栈:', errorInfo.componentStack);
  }

  handleReset = (): void => {
    this.setState({
      hasError: false,
      error: null,
      errorInfo: null,
    });
  };

  handleGoHome = (): void => {
    window.location.href = '/';
  };

  handleReload = (): void => {
    window.location.reload();
  };

  render(): ReactNode {
    const { hasError, error, errorInfo } = this.state;
    const { children, fallback } = this.props;

    if (hasError) {
      // 如果提供了自定义 fallback，使用它
      if (fallback) {
        return fallback;
      }

      const isDev = import.meta.env.DEV;

      return (
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '100vh',
          padding: 24,
          background: '#f5f5f5'
        }}>
          <Result
            status="error"
            icon={<BugOutlined style={{ color: '#ff4d4f' }} />}
            title="应用程序出现问题"
            subTitle="抱歉，应用程序遇到了一个错误。请尝试刷新页面或返回首页。"
            extra={[
              <Button
                key="reload"
                type="primary"
                icon={<ReloadOutlined />}
                onClick={this.handleReload}
              >
                刷新页面
              </Button>,
              <Button
                key="home"
                icon={<HomeOutlined />}
                onClick={this.handleGoHome}
              >
                返回首页
              </Button>,
              <Button
                key="reset"
                onClick={this.handleReset}
              >
                重试
              </Button>,
            ]}
          >
            {isDev && error && (
              <div style={{
                textAlign: 'left',
                marginTop: 24,
                padding: 16,
                background: '#fff',
                borderRadius: 8,
                maxWidth: 800
              }}>
                <Paragraph strong style={{ marginBottom: 8 }}>
                  错误详情（仅开发环境显示）:
                </Paragraph>
                <Paragraph
                  style={{
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: '#ff4d4f',
                    background: '#fff1f0',
                    padding: 12,
                    borderRadius: 4,
                    marginBottom: 8,
                    wordBreak: 'break-word'
                  }}
                >
                  {error.toString()}
                </Paragraph>
                {errorInfo && (
                  <>
                    <Paragraph strong style={{ marginBottom: 8 }}>
                      组件调用栈:
                    </Paragraph>
                    <pre
                      style={{
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: '#595959',
                        background: '#fafafa',
                        padding: 12,
                        borderRadius: 4,
                        maxHeight: 300,
                        overflow: 'auto',
                        whiteSpace: 'pre-wrap',
                        wordBreak: 'break-word'
                      }}
                    >
                      {errorInfo.componentStack}
                    </pre>
                  </>
                )}
              </div>
            )}
          </Result>
        </div>
      );
    }

    return children;
  }
}
