%% VPSO算法演示脚本
% 演示如何使用重构后的VPSO算法优化二进制问题
% 注意: VPSO专为二进制优化设计
%
% 作者: 元启发式算法工程规范委员会
% 版本: 2.0.0
% 日期: 2025

clear; clc; close all;

fprintf('========================================\n');
fprintf('V-shaped PSO (VPSO) Demo\n');
fprintf('========================================\n\n');

%% 1. 设置随机种子
rng(42, 'twister');
fprintf('Random seed: 42\n\n');

%% 2. 定义二进制优化问题
% 示例: 简单的0-1背包问题的适应度函数
% 目标: 选择一组物品使得总价值最大（转换为最小化）
dim = 50;  % 物品数量

% 随机生成物品价值和重量
weights = randi([1, 50], 1, dim);
values = randi([10, 100], 1, dim);
capacity = sum(weights) * 0.5;  % 背包容量为总重量的50%

% 定义适应度函数 (惩罚超重)
function f = knapsackFitness(x, weights, values, capacity)
    totalWeight = sum(weights .* x);
    totalValue = sum(values .* x);
    if totalWeight > capacity
        f = totalWeight - capacity + 1000;  % 惩罚超重
    else
        f = -totalValue;  % 最小化负价值 = 最大化价值
    end
end

fobj = @(x) knapsackFitness(x, weights, values, capacity);

fprintf('Binary Optimization Problem: 0-1 Knapsack\n');
fprintf('  Items: %d\n', dim);
fprintf('  Capacity: %d\n', capacity);
fprintf('  Total Weight: %d\n\n', sum(weights));

%% 3. 配置算法参数
config = struct();
config.populationSize = 30;
config.maxIterations = 200;
config.transferFunctionType = 'V4';  % 使用V4传递函数
config.wMax = 0.9;
config.wMin = 0.4;
config.c1 = 2;
config.c2 = 2;
config.vMax = 6;
config.verbose = true;

fprintf('Algorithm Configuration:\n');
fprintf('  Population Size: %d\n', config.populationSize);
fprintf('  Max Iterations: %d\n', config.maxIterations);
fprintf('  Transfer Function: %s\n\n', config.transferFunctionType);

%% 4. 创建问题对象
problem = struct();
problem.evaluate = fobj;
problem.lb = 0;
problem.ub = 1;
problem.dim = dim;

%% 5. 运行VPSO优化
fprintf('Running VPSO optimization...\n\n');

tic;
vpso = algorithms.vpso.VPSO(config);
result = vpso.run(problem);
elapsedTime = toc;

%% 6. 显示结果
fprintf('\n');
fprintf('========================================\n');
fprintf('Optimization Results\n');
fprintf('========================================\n');
fprintf('Best Fitness (negative value): %.2f\n', result.bestFitness);
fprintf('Best Value: %.2f\n', -result.bestFitness);
fprintf('Items Selected: %d / %d\n', sum(result.bestSolution), dim);

selectedWeight = sum(weights .* result.bestSolution);
fprintf('Total Weight: %d / %d (%.1f%%)\n', selectedWeight, capacity, ...
    100 * selectedWeight / capacity);
fprintf('Optimization Time: %.3f seconds\n', elapsedTime);
fprintf('Total Evaluations: %d\n\n', result.totalEvaluations);

%% 7. 绘制收敛曲线
figure('Position', [100, 100, 1000, 400]);

subplot(1, 2, 1);
plot(-result.convergenceCurve, 'b-', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Best Value');
title('VPSO Convergence (Knapsack Value)');
grid on;

subplot(1, 2, 2);
selectedItems = find(result.bestSolution);
bar(values);
hold on;
bar(selectedItems, values(selectedItems), 'r');
xlabel('Item Index');
ylabel('Value');
title('Selected vs Unselected Items');
legend('Unselected', 'Selected');
grid on;

sgtitle('VPSO Optimization Results - 0-1 Knapsack', ...
    'FontSize', 14, 'FontWeight', 'bold');

fprintf('========================================\n');
fprintf('Demo completed successfully!\n');
fprintf('========================================\n');
