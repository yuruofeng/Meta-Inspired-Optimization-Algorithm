%% MFO和MVO算法快速验证测试
% 验证新添加的MFO和MVO算法是否正常工作
%
% 作者：RUOFENG YU
% 版本: 2.0.0
% 日期: 2026

clear; clc;

fprintf('========================================\n');
fprintf('MFO and MVO Quick Validation Test\n');
fprintf('========================================\n\n');

%% 1. 注册算法
fprintf('1. Registering algorithms...\n');
MFO.register();
MVO.register();
fprintf('   ✓ Algorithms registered\n\n');

%% 2. 获取测试函数
fprintf('2. Loading benchmark function F1...\n');
Function_name = 'F1';
[lb, ub, dim, fobj] = BenchmarkFunctions.get(Function_name);
fprintf('   ✓ Function loaded (dim=%d, bounds=[%.1f, %.1f])\n\n', dim, lb, ub);

%% 3. 配置参数（快速测试）
config = struct();
config.populationSize = 20;
config.maxIterations = 100;
config.verbose = false;

problem = struct();
problem.evaluate = fobj;
problem.lb = lb;
problem.ub = ub;
problem.dim = dim;

%% 4. 测试MFO算法
fprintf('3. Testing MFO algorithm...\n');
tic;
mfo = MFO(config);
result_mfo = mfo.run(problem);
time_mfo = toc;

fprintf('   Best fitness: %.6e\n', result_mfo.bestFitness);
fprintf('   Time: %.3f seconds\n', time_mfo);
fprintf('   ✓ MFO passed\n\n');

%% 5. 测试MVO算法
fprintf('4. Testing MVO algorithm...\n');
tic;
mvo = MVO(config);
result_mvo = mvo.run(problem);
time_mvo = toc;

fprintf('   Best fitness: %.6e\n', result_mvo.bestFitness);
fprintf('   Time: %.3f seconds\n', time_mvo);
fprintf('   ✓ MVO passed\n\n');

%% 6. 验证结果
fprintf('5. Validating results...\n');
threshold = 1e-3;  % 放宽阈值用于快速测试

mfo_pass = result_mfo.bestFitness < threshold;
mvo_pass = result_mvo.bestFitness < threshold;

if mfo_pass
    fprintf('   ✓ MFO achieved required precision (< %.2e)\n', threshold);
else
    fprintf('   ⚠ MFO did not achieve required precision (%.2e)\n', result_mfo.bestFitness);
end

if mvo_pass
    fprintf('   ✓ MVO achieved required precision (< %.2e)\n', threshold);
else
    fprintf('   ⚠ MVO did not achieve required precision (%.2e)\n', result_mvo.bestFitness);
end

%% 7. 总结
fprintf('\n========================================\n');
fprintf('Validation Summary:\n');
fprintf('========================================\n');
fprintf('MFO: %s (Fitness: %.6e, Time: %.3fs)\n', ...
    ternary(mfo_pass, 'PASS', 'FAIL'), result_mfo.bestFitness, time_mfo);
fprintf('MVO: %s (Fitness: %.6e, Time: %.3fs)\n', ...
    ternary(mvo_pass, 'PASS', 'FAIL'), result_mvo.bestFitness, time_mfo);
fprintf('========================================\n\n');

% 辅助函数
function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
