%% ALO算法演示脚本
% 演示如何使用重构后的ALO算法优化基准测试函数

clear; clc; close all;

fprintf('========================================\n');
fprintf('Ant Lion Optimizer (ALO) Demo\n');
fprintf('========================================\n\n');

rng(42, 'twister');
Function_name = 'F1';

fprintf('Benchmark Function: %s\n', Function_name);
[lb, ub, dim, fobj] = BenchmarkFunctions.get(Function_name);
funcInfo = BenchmarkFunctions.getInfo(Function_name);
fprintf('  Dimension: %d, Bounds: [%.2f, %.2f]\n\n', dim, lb, ub);

config = struct('populationSize', 30, 'maxIterations', 500, 'verbose', true);
problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);

fprintf('Running ALO optimization...\n');
alo = ALO(config);
result = alo.run(problem);

result.display();

figure('Position', [100, 100, 600, 400]);
result.plotConvergence('Title', 'ALO Convergence Curve');
