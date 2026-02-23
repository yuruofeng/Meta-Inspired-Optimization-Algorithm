%% MVO算法演示脚本
% 演示如何使用重构后的MVO（多元宇宙优化）算法优化基准测试函数
%
% 作者：RUOFENG YU
% 版本: 2.0.0
% 日期: 2026

clear; clc; close all;

fprintf('========================================\n');
fprintf('Multi-Verse Optimizer (MVO) Demo\n');
fprintf('========================================\n\n');

%% 1. 设置随机种子（确保可复现性）
rng(42, 'twister');
fprintf('Random seed: 42\n\n');

%% 2. 选择测试函数
Function_name = 'F1';  % 可以选择 F1-F23

fprintf('Benchmark Function: %s\n', Function_name);

% 获取函数详情
[lb, ub, dim, fobj] = BenchmarkFunctions.get(Function_name);
funcInfo = BenchmarkFunctions.getInfo(Function_name);

fprintf('  Type: %s\n', funcInfo.type);
fprintf('  Dimension: %d\n', dim);
fprintf('  Bounds: [%.2f, %.2f]\n', lb, ub);
fprintf('  Optimal Value: %.6e\n\n', funcInfo.optimalValue);

%% 3. 配置算法参数
config = struct();
config.populationSize = 30;    % 种群大小
config.maxIterations = 500;    % 最大迭代次数
config.WEP_Min = 0.2;          % 最小虫洞存在概率
config.WEP_Max = 1.0;          % 最大虫洞存在概率
config.verbose = true;         % 显示进度

fprintf('Algorithm Configuration:\n');
fprintf('  Population Size: %d\n', config.populationSize);
fprintf('  Max Iterations: %d\n', config.maxIterations);
fprintf('  WEP Range: [%.2f, %.2f]\n\n', config.WEP_Min, config.WEP_Max);

%% 4. 创建问题对象
problem = struct();
problem.evaluate = fobj;
problem.lb = lb;
problem.ub = ub;
problem.dim = dim;

%% 5. 运行MVO优化
fprintf('Running MVO optimization...\n\n');

tic;
mvo = MVO(config);
result = mvo.run(problem);
elapsedTime = toc;

%% 6. 显示结果
fprintf('\n');
result.display();

fprintf('Optimization Time: %.3f seconds\n\n', elapsedTime);

%% 7. 绘制收敛曲线
figure('Position', [100, 100, 1200, 400]);

% 子图1: 测试函数可视化（仅2D）
subplot(1, 2, 1);
if dim == 2
    % 绘制函数表面
    [X, Y] = meshgrid(linspace(lb, ub, 100), linspace(lb, ub, 100));
    Z = zeros(size(X));
    for i = 1:size(X, 1)
        for j = 1:size(X, 2)
            Z(i, j) = fobj([X(i, j), Y(i, j)]);
        end
    end
    surfc(X, Y, Z, 'EdgeColor', 'none');
    colorbar;
    hold on;
    plot3(result.bestSolution(1), result.bestSolution(2), ...
        result.bestFitness, 'r*', 'MarkerSize', 20, 'LineWidth', 3);
    xlabel('x_1');
    ylabel('x_2');
    zlabel('f(x)');
    title(sprintf('%s Function (2D View)', Function_name));
else
    % 高维函数显示示意图
    text(0.5, 0.5, sprintf(['Function dimension: %d\n\n(Best solution and ' ...
        'fitness shown in command window)'], dim), ...
        'HorizontalAlignment', 'center', 'FontSize', 12);
    axis off;
    title(sprintf('%s Function', Function_name));
end

% 子图2: 收敛曲线
subplot(1, 2, 2);
result.plotConvergence('Title', 'MVO Convergence Curve', 'Scale', 'log');

sgtitle(sprintf('MVO Optimization Results - %s', Function_name), ...
    'FontSize', 14, 'FontWeight', 'bold');

%% 8. 验证精度要求（根据规范 §6.2）
if strcmp(Function_name, 'F1')
    threshold = 1e-10;
    if result.bestFitness < threshold
        fprintf('✓ PASS: Achieved required precision (< %.2e)\n', threshold);
    else
        fprintf('✗ FAIL: Did not achieve required precision (%.2e >= %.2e)\n', ...
            result.bestFitness, threshold);
    end
end

fprintf('\n========================================\n');
fprintf('Demo completed successfully!\n');
fprintf('========================================\n');
