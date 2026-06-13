% demo_moalgorithms 多目标优化算法演示
%
% 演示5种多目标优化算法的使用方法:
%   - MOALO: 多目标蚁狮优化器
%   - MODA:  多目标蜻蜓算法
%   - MOGOA: 多目标蚱蜢优化算法
%   - MOGWO: 多目标灰狼优化器
%   - MSSA:  多目标樽海鞘群算法
%
% 使用ZDT1测试问题展示Pareto前沿的获取和可视化
%
% 作者：RUOFENG YU
% 版本: 1.0.0
% 日期: 2025

clear;
clc;
close all;

fprintf('========================================\n');
fprintf('多目标优化算法演示\n');
fprintf('========================================\n\n');

problem.lb = 0;
problem.ub = 1;
problem.dim = 30;
problem.objCount = 2;
problem.evaluate = @ZDT1_evaluate;

config = struct();
config.populationSize = 100;
config.maxIterations = 100;
config.archiveMaxSize = 100;
config.verbose = true;

algorithms = {'MOALO', 'MODA', 'MOGOA', 'MOGWO', 'MSSA'};
constructors = {@MOALO, @MODA, @MOGOA, @MOGWO, @MSSA};
colors = {'k', 'b', 'r', 'g', 'm'};

results = cell(1, length(algorithms));

for i = 1:length(algorithms)
    fprintf('\n运行 %s 算法...\n', algorithms{i});
    tic;
    algo = constructors{i}(config);
    results{i} = algo.run(problem);
    elapsed = toc;
    fprintf('%s 完成，耗时: %.2f 秒\n', algorithms{i}, elapsed);
    fprintf('Pareto解数量: %d\n\n', results{i}.archiveSize);
end

fprintf('\n========================================\n');
fprintf('结果可视化\n');
fprintf('========================================\n');

figure('Position', [100, 100, 1200, 500]);

subplot(1, 2, 1);
true_pf = generateZDT1TruePF(100);
plot(true_pf(:, 1), true_pf(:, 2), 'k-', 'LineWidth', 1.5, 'DisplayName', 'True PF');
hold on;

for i = 1:length(algorithms)
    pf = results{i}.paretoFront;
    plot(pf(:, 1), pf(:, 2), ['o', colors{i}], ...
        'MarkerSize', 4, 'MarkerFaceColor', colors{i}, ...
        'DisplayName', algorithms{i});
end

xlabel('f_1');
ylabel('f_2');
title('Pareto Front Comparison');
legend('Location', 'best');
grid on;
hold off;

subplot(1, 2, 2);
barData = zeros(length(algorithms), 1);
for i = 1:length(algorithms)
    barData(i) = results{i}.archiveSize;
end

bar(barData);
set(gca, 'XTickLabel', algorithms);
ylabel('Number of Pareto Solutions');
title('Archive Size Comparison');
grid on;

fprintf('\n========================================\n');
fprintf('性能摘要\n');
fprintf('========================================\n');
fprintf('%-10s %-15s %-15s\n', 'Algorithm', 'Archive Size', 'Time (s)');
fprintf('%-10s %-15s %-15s\n', '---------', '------------', '--------');

for i = 1:length(algorithms)
    fprintf('%-10s %-15d %-15.2f\n', algorithms{i}, ...
        results{i}.archiveSize, results{i}.elapsedTime);
end

fprintf('\n演示完成!\n');

function fitness = ZDT1_evaluate(x)
    n = length(x);
    f1 = x(1);
    g = 1 + 9 * sum(x(2:n)) / (n - 1);
    h = 1 - sqrt(f1 / g);
    f2 = g * h;
    fitness = [f1, f2];
end

function pf = generateZDT1TruePF(n)
    pf = zeros(n, 2);
    for i = 1:n
        f1 = (i - 1) / (n - 1);
        f2 = 1 - sqrt(f1);
        pf(i, :) = [f1, f2];
    end
end
