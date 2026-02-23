%% 算法对比演示脚本
% 对比ALO, GWO, IGWO三种算法在同一测试函数上的性能
%
% 作者: 元启发式算法工程规范委员会
% 版本: 2.0.0
% 日期: 2025

clear; clc; close all;

fprintf('========================================\n');
fprintf('Algorithm Comparison Demo\n');
fprintf('ALO vs GWO vs IGWO\n');
fprintf('========================================\n\n');

%% 设置
rng(42, 'twister');
Function_name = 'F1';  % 可以选择 F1-F23

fprintf('Benchmark Function: %s\n', Function_name);
[lb, ub, dim, fobj] = BenchmarkFunctions.get(Function_name);
fprintf('  Dimension: %d\n', dim);
fprintf('  Bounds: [%.2f, %.2f]\n\n', lb, ub);

%% 配置
config = struct('populationSize', 30, 'maxIterations', 500, 'verbose', false);
problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);

%% 运行三种算法
algorithms = {'ALO', 'GWO', 'IGWO'};
results = cell(1, 3);
times = zeros(1, 3);

fprintf('Running optimizations...\n');

for i = 1:3
    fprintf('  Running %s...', algorithms{i});
    tic;
    switch algorithms{i}
        case 'ALO'
            alg = ALO(config);
        case 'GWO'
            alg = GWO(config);
        case 'IGWO'
            alg = IGWO(config);
    end
    results{i} = alg.run(problem);
    times(i) = toc;
    fprintf(' Done (%.3fs)\n', times(i));
end
fprintf('\n');

%% 对比结果
fprintf('========================================\n');
fprintf('Comparison Results\n');
fprintf('========================================\n\n');

fprintf('%-10s %15s %15s %15s\n', 'Algorithm', 'Best Fitness', 'Evaluations', 'Time (s)');
fprintf('%-10s %15s %15s %15s\n', '----------', '---------------', '---------------', '---------------');
for i = 1:3
    fprintf('%-10s %15.6e %15d %15.3f\n', ...
        algorithms{i}, results{i}.bestFitness, ...
        results{i}.totalEvaluations, times(i));
end
fprintf('\n');

% 找到最优算法
[bestFitness, bestIdx] = min([results{:}.bestFitness]);
fprintf('Best Algorithm: %s (%.6e)\n\n', algorithms{bestIdx}, bestFitness);

%% 绘制对比图
figure('Position', [100, 100, 1000, 600]);

% 子图1: 收敛曲线对比
subplot(2, 2, 1);
hold on;
colors = {'b', 'r', 'g'};
for i = 1:3
    semilogy(1:length(results{i}.convergenceCurve), ...
        results{i}.convergenceCurve, ...
        [colors{i} '-'], 'LineWidth', 2, 'DisplayName', algorithms{i});
end
hold off;
grid on;
xlabel('Iteration');
ylabel('Best Fitness (log scale)');
title('Convergence Comparison');
legend('Location', 'best');

% 子图2: 最终适应度对比
subplot(2, 2, 2);
bar([results{:}.bestFitness]);
set(gca, 'XTickLabel', algorithms);
ylabel('Best Fitness');
title('Final Fitness Comparison');
grid on;

% 子图3: 运行时间对比
subplot(2, 2, 3);
bar(times);
set(gca, 'XTickLabel', algorithms);
ylabel('Time (seconds)');
title('Execution Time Comparison');
grid on;

% 子图4: 总评估次数对比
subplot(2, 2, 4);
bar([results{:}.totalEvaluations]);
set(gca, 'XTickLabel', algorithms);
ylabel('Total Evaluations');
title('Function Evaluations Comparison');
grid on;

sgtitle(sprintf('Algorithm Comparison - %s Function', Function_name), ...
    'FontSize', 14, 'FontWeight', 'bold');

%% 保存对比结果
fprintf('Saving comparison results...\n');
comparisonData = struct();
for i = 1:3
    comparisonData.(algorithms{i}) = results{i}.toStruct();
    comparisonData.(algorithms{i}).elapsedTime = times(i);
end
save(sprintf('comparison_%s.mat', Function_name), 'comparisonData');
fprintf('Results saved to: comparison_%s.mat\n\n', Function_name);

fprintf('========================================\n');
fprintf('Comparison completed successfully!\n');
fprintf('========================================\n');
