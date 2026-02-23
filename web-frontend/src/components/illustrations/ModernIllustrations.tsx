/**
 * 现代化插画组件
 * 基于扁平化设计风格，支持主题自适应
 */

import { Typography } from 'antd';
import type { CSSProperties } from 'react';

const { Title, Text } = Typography;

// 重新导出 Illustration.tsx 中的类型以保持一致性
export type { IllustrationSize, IllustrationTheme, IllustrationProps } from './Illustration';

// 内部使用的尺寸类型（不包含 xs 和 full）
type InternalSize = 'sm' | 'md' | 'lg' | 'xl';

interface BaseIllustrationProps {
  size?: InternalSize;
  title?: string;
  description?: string;
  primaryColor?: string;
  className?: string;
  style?: CSSProperties;
}

const sizeMap: Record<InternalSize, number> = {
  sm: 120,
  md: 200,
  lg: 320,
  xl: 480,
};

// 欢迎插画 - 用于首页
export function WelcomeIllustration({
  size = 'md',
  title,
  description,
  primaryColor = '#1677ff',
  className,
  style,
}: BaseIllustrationProps) {
  const dimension = sizeMap[size];

  return (
    <div className={`illustration illustration--${size} ${className || ''}`} style={style}>
      <svg
        width={dimension}
        height={dimension * 0.75}
        viewBox="0 0 400 300"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* 背景圆 */}
        <circle cx="200" cy="150" r="120" fill={primaryColor} opacity="0.1" />

        {/* 数据可视化图形 */}
        <rect x="100" y="180" width="40" height="60" rx="4" fill={primaryColor} opacity="0.8" />
        <rect x="160" y="140" width="40" height="100" rx="4" fill={primaryColor} opacity="0.9" />
        <rect x="220" y="100" width="40" height="140" rx="4" fill={primaryColor} />
        <rect x="280" y="160" width="40" height="80" rx="4" fill={primaryColor} opacity="0.7" />

        {/* 趋势线 */}
        <path
          d="M120 170 L180 130 L240 90 L300 150"
          stroke={primaryColor}
          strokeWidth="3"
          strokeLinecap="round"
          strokeLinejoin="round"
          fill="none"
          opacity="0.6"
        />

        {/* 装饰点 */}
        <circle cx="120" cy="170" r="6" fill={primaryColor} />
        <circle cx="180" cy="130" r="6" fill={primaryColor} />
        <circle cx="240" cy="90" r="6" fill={primaryColor} />
        <circle cx="300" cy="150" r="6" fill={primaryColor} />

        {/* 人物剪影 */}
        <circle cx="200" cy="50" r="15" fill={primaryColor} opacity="0.4" />
        <path
          d="M185 70 L185 95 M215 70 L215 95 M185 82 L215 82"
          stroke={primaryColor}
          strokeWidth="3"
          strokeLinecap="round"
          opacity="0.4"
        />
      </svg>

      {title && <Title level={4} style={{ marginTop: 16, marginBottom: 4 }}>{title}</Title>}
      {description && <Text type="secondary">{description}</Text>}
    </div>
  );
}

// 空数据插画
export function EmptyDataIllustration({
  size = 'md',
  title,
  description,
  primaryColor = '#1677ff',
  className,
  style,
}: BaseIllustrationProps) {
  const dimension = sizeMap[size];

  return (
    <div className={`illustration illustration--${size} ${className || ''}`} style={style}>
      <svg
        width={dimension}
        height={dimension * 0.75}
        viewBox="0 0 400 300"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* 空盒子 */}
        <rect
          x="120"
          y="100"
          width="160"
          height="120"
          rx="8"
          stroke={primaryColor}
          strokeWidth="3"
          strokeDasharray="8 4"
          fill="none"
        />

        {/* 放大镜 */}
        <circle cx="200" cy="160" r="30" stroke={primaryColor} strokeWidth="3" fill="none" />
        <line
          x1="222"
          y1="182"
          x2="245"
          y2="205"
          stroke={primaryColor}
          strokeWidth="3"
          strokeLinecap="round"
        />

        {/* 问号 */}
        <text
          x="200"
          y="170"
          textAnchor="middle"
          fontSize="28"
          fontWeight="bold"
          fill={primaryColor}
          opacity="0.5"
        >
          ?
        </text>

        {/* 装饰元素 */}
        <circle cx="100" cy="80" r="8" fill={primaryColor} opacity="0.2" />
        <circle cx="300" cy="90" r="6" fill={primaryColor} opacity="0.3" />
        <circle cx="320" cy="220" r="10" fill={primaryColor} opacity="0.15" />
      </svg>

      {title && <Title level={4} style={{ marginTop: 16, marginBottom: 4 }}>{title}</Title>}
      {description && <Text type="secondary">{description}</Text>}
    </div>
  );
}

// 404 页面插画
export function NotFoundIllustration({
  size = 'md',
  title,
  description,
  primaryColor = '#1677ff',
  className,
  style,
}: BaseIllustrationProps) {
  const dimension = sizeMap[size];

  return (
    <div className={`illustration illustration--${size} ${className || ''}`} style={style}>
      <svg
        width={dimension}
        height={dimension * 0.75}
        viewBox="0 0 400 300"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* 断开的路径 */}
        <path
          d="M80 200 L140 200 L160 180 L180 220 L200 180 L220 220 L240 180 L260 200 L320 200"
          stroke={primaryColor}
          strokeWidth="4"
          strokeLinecap="round"
          strokeLinejoin="round"
          fill="none"
          opacity="0.3"
        />

        {/* 404 大字 */}
        <text
          x="200"
          y="150"
          textAnchor="middle"
          fontSize="72"
          fontWeight="bold"
          fill={primaryColor}
        >
          404
        </text>

        {/* 地图标记 */}
        <circle cx="200" cy="220" r="15" stroke={primaryColor} strokeWidth="3" fill="none" />
        <circle cx="200" cy="220" r="5" fill={primaryColor} />
        <path
          d="M200 205 L200 180"
          stroke={primaryColor}
          strokeWidth="3"
          strokeLinecap="round"
        />

        {/* 装饰 */}
        <circle cx="80" cy="100" r="20" fill={primaryColor} opacity="0.1" />
        <circle cx="320" cy="120" r="15" fill={primaryColor} opacity="0.15" />
      </svg>

      {title && <Title level={4} style={{ marginTop: 16, marginBottom: 4 }}>{title}</Title>}
      {description && <Text type="secondary">{description}</Text>}
    </div>
  );
}

// 500 错误插画
export function ServerErrorIllustration({
  size = 'md',
  title,
  description,
  primaryColor = '#ff4d4f',
  className,
  style,
}: BaseIllustrationProps) {
  const dimension = sizeMap[size];

  return (
    <div className={`illustration illustration--${size} ${className || ''}`} style={style}>
      <svg
        width={dimension}
        height={dimension * 0.75}
        viewBox="0 0 400 300"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* 服务器 */}
        <rect x="140" y="80" width="120" height="140" rx="8" stroke={primaryColor} strokeWidth="3" fill="none" />
        <rect x="160" y="100" width="80" height="8" rx="2" fill={primaryColor} opacity="0.3" />
        <rect x="160" y="120" width="80" height="8" rx="2" fill={primaryColor} opacity="0.3" />
        <rect x="160" y="140" width="80" height="8" rx="2" fill={primaryColor} opacity="0.3" />

        {/* 错误叉号 */}
        <circle cx="260" cy="100" r="25" fill={primaryColor} opacity="0.1" />
        <path
          d="M248 88 L272 112 M272 88 L248 112"
          stroke={primaryColor}
          strokeWidth="4"
          strokeLinecap="round"
        />

        {/* 警告三角 */}
        <path
          d="M200 180 L215 210 L185 210 Z"
          stroke={primaryColor}
          strokeWidth="2"
          fill="none"
        />
        <line x1="200" y1="190" x2="200" y2="200" stroke={primaryColor} strokeWidth="2" strokeLinecap="round" />
        <circle cx="200" cy="205" r="2" fill={primaryColor} />

        {/* 装饰线条 */}
        <line x1="100" y1="250" x2="300" y2="250" stroke={primaryColor} strokeWidth="2" opacity="0.2" />
      </svg>

      {title && <Title level={4} style={{ marginTop: 16, marginBottom: 4 }}>{title}</Title>}
      {description && <Text type="secondary">{description}</Text>}
    </div>
  );
}

// 加载插画
export function LoadingIllustration({
  size = 'md',
  title,
  description,
  primaryColor = '#1677ff',
  className,
  style,
}: BaseIllustrationProps) {
  const dimension = sizeMap[size];

  return (
    <div className={`illustration illustration--${size} ${className || ''}`} style={style}>
      <svg
        width={dimension}
        height={dimension * 0.75}
        viewBox="0 0 400 300"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* 旋转的圆环 */}
        <circle
          cx="200"
          cy="130"
          r="50"
          stroke={primaryColor}
          strokeWidth="6"
          strokeDasharray="80 40"
          strokeLinecap="round"
          fill="none"
          opacity="0.3"
        >
          <animateTransform
            attributeName="transform"
            type="rotate"
            from="0 200 130"
            to="360 200 130"
            dur="1.5s"
            repeatCount="indefinite"
          />
        </circle>

        {/* 内部图形 */}
        <rect x="185" y="115" width="30" height="30" rx="4" fill={primaryColor} opacity="0.6">
          <animate
            attributeName="opacity"
            values="0.6;0.3;0.6"
            dur="1.5s"
            repeatCount="indefinite"
          />
        </rect>

        {/* 进度点 */}
        <circle cx="170" cy="220" r="8" fill={primaryColor} opacity="0.3">
          <animate attributeName="opacity" values="0.3;1;0.3" dur="1.5s" begin="0s" repeatCount="indefinite" />
        </circle>
        <circle cx="200" cy="220" r="8" fill={primaryColor} opacity="0.3">
          <animate attributeName="opacity" values="0.3;1;0.3" dur="1.5s" begin="0.2s" repeatCount="indefinite" />
        </circle>
        <circle cx="230" cy="220" r="8" fill={primaryColor} opacity="0.3">
          <animate attributeName="opacity" values="0.3;1;0.3" dur="1.5s" begin="0.4s" repeatCount="indefinite" />
        </circle>
      </svg>

      {title && <Title level={4} style={{ marginTop: 16, marginBottom: 4 }}>{title}</Title>}
      {description && <Text type="secondary">{description}</Text>}
    </div>
  );
}

// 成功插画
export function SuccessIllustration({
  size = 'md',
  title,
  description,
  primaryColor = '#52c41a',
  className,
  style,
}: BaseIllustrationProps) {
  const dimension = sizeMap[size];

  return (
    <div className={`illustration illustration--${size} ${className || ''}`} style={style}>
      <svg
        width={dimension}
        height={dimension * 0.75}
        viewBox="0 0 400 300"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* 成功圆圈 */}
        <circle cx="200" cy="130" r="60" stroke={primaryColor} strokeWidth="4" fill="none" opacity="0.2" />
        <circle cx="200" cy="130" r="45" fill={primaryColor} opacity="0.1" />

        {/* 对勾 */}
        <path
          d="M170 130 L190 150 L235 105"
          stroke={primaryColor}
          strokeWidth="6"
          strokeLinecap="round"
          strokeLinejoin="round"
          fill="none"
        />

        {/* 装饰星星 */}
        <path d="M120 80 L125 90 L135 90 L127 97 L130 107 L120 100 L110 107 L113 97 L105 90 L115 90 Z" fill={primaryColor} opacity="0.3" />
        <path d="M280 100 L283 107 L290 107 L285 112 L287 119 L280 115 L273 119 L275 112 L270 107 L277 107 Z" fill={primaryColor} opacity="0.4" />
        <path d="M300 180 L303 187 L310 187 L305 192 L307 199 L300 195 L293 199 L295 192 L290 187 L297 187 Z" fill={primaryColor} opacity="0.2" />

        {/* 装饰圆点 */}
        <circle cx="100" cy="200" r="6" fill={primaryColor} opacity="0.2" />
        <circle cx="310" cy="220" r="8" fill={primaryColor} opacity="0.3" />
      </svg>

      {title && <Title level={4} style={{ marginTop: 16, marginBottom: 4 }}>{title}</Title>}
      {description && <Text type="secondary">{description}</Text>}
    </div>
  );
}

// 算法插画 - 用于算法相关页面
export function AlgorithmIllustration({
  size = 'md',
  title,
  description,
  primaryColor = '#1677ff',
  className,
  style,
}: BaseIllustrationProps) {
  const dimension = sizeMap[size];

  return (
    <div className={`illustration illustration--${size} ${className || ''}`} style={style}>
      <svg
        width={dimension}
        height={dimension * 0.75}
        viewBox="0 0 400 300"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* 优化路径 */}
        <path
          d="M80 220 Q150 200 180 160 Q200 130 220 140 Q250 150 280 100 Q310 60 340 80"
          stroke={primaryColor}
          strokeWidth="3"
          strokeLinecap="round"
          fill="none"
        />

        {/* 节点 */}
        <circle cx="80" cy="220" r="8" fill={primaryColor} opacity="0.3" />
        <circle cx="180" cy="160" r="8" fill={primaryColor} opacity="0.5" />
        <circle cx="220" cy="140" r="8" fill={primaryColor} opacity="0.6" />
        <circle cx="280" cy="100" r="8" fill={primaryColor} opacity="0.8" />
        <circle cx="340" cy="80" r="10" fill={primaryColor} />

        {/* 目标点光芒 */}
        <line x1="340" y1="60" x2="340" y2="45" stroke={primaryColor} strokeWidth="2" strokeLinecap="round" />
        <line x1="360" y1="80" x2="375" y2="80" stroke={primaryColor} strokeWidth="2" strokeLinecap="round" />
        <line x1="355" y1="65" x2="368" y2="52" stroke={primaryColor} strokeWidth="2" strokeLinecap="round" />

        {/* 搜索区域 */}
        <ellipse cx="180" cy="180" rx="80" ry="50" stroke={primaryColor} strokeWidth="2" strokeDasharray="4 2" fill="none" opacity="0.2" />

        {/* 粒子/代理 */}
        <circle cx="150" cy="200" r="4" fill={primaryColor} opacity="0.6">
          <animate attributeName="cy" values="200;190;200" dur="2s" repeatCount="indefinite" />
        </circle>
        <circle cx="200" cy="170" r="4" fill={primaryColor} opacity="0.6">
          <animate attributeName="cy" values="170;160;170" dur="2s" begin="0.3s" repeatCount="indefinite" />
        </circle>
        <circle cx="170" cy="150" r="4" fill={primaryColor} opacity="0.6">
          <animate attributeName="cy" values="150;140;150" dur="2s" begin="0.6s" repeatCount="indefinite" />
        </circle>
      </svg>

      {title && <Title level={4} style={{ marginTop: 16, marginBottom: 4 }}>{title}</Title>}
      {description && <Text type="secondary">{description}</Text>}
    </div>
  );
}

// 对比插画
export function ComparisonIllustration({
  size = 'md',
  title,
  description,
  primaryColor = '#1677ff',
  className,
  style,
}: BaseIllustrationProps) {
  const dimension = sizeMap[size];

  return (
    <div className={`illustration illustration--${size} ${className || ''}`} style={style}>
      <svg
        width={dimension}
        height={dimension * 0.75}
        viewBox="0 0 400 300"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* 左侧图表 */}
        <rect x="60" y="140" width="30" height="80" rx="4" fill="#3B82F6" opacity="0.8" />
        <rect x="100" y="100" width="30" height="120" rx="4" fill="#3B82F6" opacity="0.6" />

        {/* 中间对比符号 */}
        <circle cx="200" cy="150" r="25" stroke={primaryColor} strokeWidth="2" fill="none" />
        <path d="M190 145 L200 155 L210 145 M190 155 L200 145 L210 155" stroke={primaryColor} strokeWidth="2" strokeLinecap="round" />

        {/* 右侧图表 */}
        <rect x="270" y="120" width="30" height="100" rx="4" fill="#10B981" opacity="0.6" />
        <rect x="310" y="80" width="30" height="140" rx="4" fill="#10B981" opacity="0.8" />

        {/* 连接线 */}
        <line x1="140" y1="150" x2="170" y2="150" stroke={primaryColor} strokeWidth="2" strokeDasharray="4 2" opacity="0.5" />
        <line x1="230" y1="150" x2="260" y2="150" stroke={primaryColor} strokeWidth="2" strokeDasharray="4 2" opacity="0.5" />

        {/* 标签 */}
        <text x="95" y="240" textAnchor="middle" fontSize="12" fill={primaryColor} opacity="0.6">算法 A</text>
        <text x="305" y="240" textAnchor="middle" fontSize="12" fill={primaryColor} opacity="0.6">算法 B</text>
      </svg>

      {title && <Title level={4} style={{ marginTop: 16, marginBottom: 4 }}>{title}</Title>}
      {description && <Text type="secondary">{description}</Text>}
    </div>
  );
}

// 导出所有插画
export const illustrations = {
  welcome: WelcomeIllustration,
  empty: EmptyDataIllustration,
  notFound: NotFoundIllustration,
  serverError: ServerErrorIllustration,
  loading: LoadingIllustration,
  success: SuccessIllustration,
  algorithm: AlgorithmIllustration,
  comparison: ComparisonIllustration,
};
