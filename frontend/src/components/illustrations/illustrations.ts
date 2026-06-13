/**
 * 插画组件常量
 */

import type { ComponentType } from 'react';
import type { IllustrationProps } from './ModernIllustrations';
import {
  WelcomeIllustration,
  EmptyDataIllustration,
  NotFoundIllustration,
  ServerErrorIllustration,
  LoadingIllustration,
  SuccessIllustration,
  AlgorithmIllustration,
  ComparisonIllustration,
} from './ModernIllustrations';

export const illustrations: Record<string, ComponentType<IllustrationProps>> = {
  welcome: WelcomeIllustration,
  empty: EmptyDataIllustration,
  notFound: NotFoundIllustration,
  serverError: ServerErrorIllustration,
  loading: LoadingIllustration,
  success: SuccessIllustration,
  algorithm: AlgorithmIllustration,
  comparison: ComparisonIllustration,
};
