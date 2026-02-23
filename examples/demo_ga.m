%% GA算法演示脚本
% 演示如何使用重构后的GA算法优化基准测试函数
%
% 作者: 元启发式算法工程规范委员会
% 版本: 2.0.0
% 日期: 2025

clear; clc; close all;

fprintf('========================================\n');
fprintf('Genetic Algorithm (GA) Demo\n');
fprintf('========================================\n\n');

%% 1. 设置随机种子
rng(42, 'twister');
fprintf('Random seed: 42\n\n');

%% 2. 选择测试函数
Function_name = 'F1';

fprintf('Benchmark Function: %s\n', Function_name);

[lb, ub, dim, fobj] = BenchmarkFunctions.get(Function_name);
funcInfo = BenchmarkFunctions.getInfo(Function_name);

fprintf('  Type: %s\n', funcInfo.type);
fprintf('  Dimension: %d\n', dim);
fprintf('  Bounds: [%.2f, %.2f]\n', lb, ub);
fprintf('  Optimal Value: %.6e\n\n', funcInfo.optimalValue);

%% 3. 配置算法参数
config = struct();
config.populationSize = 50;
config.maxIterations = 500;
config.mutationRate = 0.01;
config.crossoverRate = 0.9;
config.elitismCount = 2;
config.selection = 'tournament';
config.tournamentSize = 3;
config.verbose = true;

fprintf('Algorithm Configuration:\n');
fprintf('  Population Size: %d\n', config.populationSize);
fprintf('  Max Iterations: %d\n', config.maxIterations);
fprintf('  Mutation Rate: %.2f\n', config.mutationRate);
fprintf('  Crossover Rate: %.2f\n', config.crossoverRate);
fprintf('  Elitism Count: %d\n\n', config.elitismCount);

%% 4. 创建问题对象
problem = struct();
problem.evaluate = fobj;
problem.lb = lb;
problem.ub = ub;
problem.dim = dim;

%% 5. 运行GA优化
fprintf('Running GA optimization...\n\n');

tic;
ga = algorithms.ga.GA(config);
result = ga.run(problem);
elapsedTime = toc;

%% 6. 显示结果
fprintf('\n');
result.display();

fprintf('Optimization Time: %.3f seconds\n\n', elapsedTime);

%% 7. 绘制收敛曲线
figure('Position', [100, 100, 1200, 400]);

subplot(1, 2, 1);
if dim == 2
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
    text(0.5, 0.5, sprintf('Function dimension: %d', dim), ...
        'HorizontalAlignment', 'center', 'FontSize', 12);
    axis off;
    title(sprintf('%s Function', Function_name));
end

subplot(1, 2, 2);
result.plotConvergence('Title', 'GA Convergence Curve', 'Scale', 'log');

sgtitle(sprintf('GA Optimization Results - %s', Function_name), ...
    'FontSize', 14, 'FontWeight', 'bold');

fprintf('\n========================================\n');
fprintf('Demo completed successfully!\n');
fprintf('========================================\n');
