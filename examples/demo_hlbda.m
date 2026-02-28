%% HLBDA算法演示脚本
% 演示如何使用重构后的HLBDA算法进行二进制优化
%
% 作者：RUOFENG YU
% 版本: 2.0.0
% 日期: 2026

clear; clc; close all;

fprintf('========================================\n');
fprintf('Hyper Learning Binary Dragonfly Algorithm (HLBDA) Demo\n');
fprintf('========================================\n\n');

%% 1. 设置随机种子
rng(42, 'twister');
fprintf('Random seed: 42\n\n');

%% 2. 定义一个二进制优化问题
dim = 30;

fprintf('Binary Optimization Problem:\n');
fprintf('  Dimension: %d\n', dim);
fprintf('  Solution Space: Binary {0, 1}\n\n');

binFobj = @(x) sum(x.^2) + 0.1 * sum((1 - x).^2);

lb = 0;
ub = 1;

%% 3. 配置算法参数
config = struct();
config.populationSize = 20;
config.maxIterations = 100;
config.pp = 0.4;
config.pg = 0.7;
config.Dmax = 6;
config.verbose = true;

fprintf('Algorithm Configuration:\n');
fprintf('  Population Size: %d\n', config.populationSize);
fprintf('  Max Iterations: %d\n', config.maxIterations);
fprintf('  Personal Learning Prob (pp): %.2f\n', config.pp);
fprintf('  Global Learning Prob (pg): %.2f\n\n', config.pg);

%% 4. 创建问题对象
problem = struct();
problem.evaluate = binFobj;
problem.lb = lb;
problem.ub = ub;
problem.dim = dim;

%% 5. 运行HLBDA优化
fprintf('Running HLBDA optimization...\n\n');

tic;
hlbda = HLBDA(config);
result = hlbda.run(problem);
elapsedTime = toc;

%% 6. 显示结果
fprintf('\n');
result.display();

fprintf('Optimization Time: %.3f seconds\n\n', elapsedTime);

numOnes = sum(result.bestSolution);
fprintf('Number of 1s in solution: %d / %d\n', numOnes, dim);
fprintf('Number of 0s in solution: %d / %d\n\n', dim - numOnes, dim);

%% 7. 绘制收敛曲线
figure('Position', [100, 100, 1000, 400]);

subplot(1, 2, 1);
result.plotConvergence('Title', 'HLBDA Convergence Curve');

subplot(1, 2, 2);
bar(result.bestSolution, 'FaceColor', [0.3 0.6 0.9]);
xlabel('Dimension');
ylabel('Binary Value');
title('Best Binary Solution');
ylim([-0.2, 1.2]);
grid on;

sgtitle('HLBDA Optimization Results', 'FontSize', 14, 'FontWeight', 'bold');

fprintf('========================================\n');
fprintf('Demo completed successfully!\n');
fprintf('========================================\n');
