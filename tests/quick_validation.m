%% 快速验证测试脚本
% 验证重构后的算法是否能正常运行并产生合理结果
%
% 作者：RUOFENG YU
% 版本: 2.0.0
% 日期: 2025

clear; clc; close all;

fprintf('========================================\n');
fprintf('Quick Validation Test\n');
fprintf('========================================\n\n');

%% 测试配置
testFunctions = {'F1', 'F9', 'F10'};  % Sphere, Rastrigin, Ackley
algorithms = {'GWO', 'ALO', 'IGWO'};
populationSize = 30;
maxIterations = 100;  % 使用较少迭代次数进行快速测试

results = struct();
allPassed = true;

fprintf('Testing %d algorithms on %d functions...\n\n', ...
    length(algorithms), length(testFunctions));

%% 运行测试
for algIdx = 1:length(algorithms)
    algName = algorithms{algIdx};
    results.(algName) = struct();

    for funcIdx = 1:length(testFunctions)
        funcName = testFunctions{funcIdx};

        fprintf('Testing %s on %s... ', algName, funcName);

        try
            % 设置随机种子
            rng(42, 'twister');

            % 获取测试函数
            [lb, ub, dim, fobj] = BenchmarkFunctions.get(funcName);

            % 创建问题对象
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;

            % 配置算法
            config = struct();
            config.populationSize = populationSize;
            config.maxIterations = maxIterations;
            config.verbose = false;

            % 创建并运行算法
            switch algName
                case 'GWO'
                    algorithm = GWO(config);
                case 'ALO'
                    algorithm = ALO(config);
                case 'IGWO'
                    algorithm = IGWO(config);
            end

            tic;
            result = algorithm.run(problem);
            elapsedTime = toc;

            % 保存结果
            results.(algName).(funcName) = struct();
            results.(algName).(funcName).bestFitness = result.bestFitness;
            results.(algName).(funcName).totalEvaluations = result.totalEvaluations;
            results.(algName).(funcName).elapsedTime = elapsedTime;
            results.(algName).(funcName).converged = length(result.convergenceCurve) == maxIterations;

            % 验证基本要求
            passed = true;

            % 检查1: 结果类型正确
            if ~isa(result, 'OptimizationResult')
                passed = false;
                fprintf('FAIL (wrong result type)\n');
            end

            % 检查2: 收敛曲线长度正确
            if length(result.convergenceCurve) ~= maxIterations
                passed = false;
                fprintf('FAIL (wrong convergence curve length)\n');
            end

            % 检查3: 评估次数合理
            expectedMinEvaluations = populationSize;  % 至少评估初始种群
            if result.totalEvaluations < expectedMinEvaluations
                passed = false;
                fprintf('FAIL (too few evaluations)\n');
            end

            % 检查4: 适应度为有限值
            if ~isfinite(result.bestFitness)
                passed = false;
                fprintf('FAIL (infinite fitness)\n');
            end

            if passed
                fprintf('PASS (%.2e in %.3fs)\n', result.bestFitness, elapsedTime);
            else
                allPassed = false;
            end

        catch ME
            fprintf('ERROR: %s\n', ME.message);
            results.(algName).(funcName).error = ME.message;
            allPassed = false;
        end
    end
    fprintf('\n');
end

%% 测试总结
fprintf('========================================\n');
fprintf('Test Summary\n');
fprintf('========================================\n\n');

totalTests = length(algorithms) * length(testFunctions);
passedTests = 0;

for algIdx = 1:length(algorithms)
    algName = algorithms{algIdx};
    for funcIdx = 1:length(testFunctions)
        funcName = testFunctions{funcIdx};
        if isfield(results.(algName).(funcName), 'bestFitness')
            passedTests = passedTests + 1;
        end
    end
end

fprintf('Total Tests: %d\n', totalTests);
fprintf('Passed: %d\n', passedTests);
fprintf('Failed: %d\n', totalTests - passedTests);
fprintf('Success Rate: %.1f%%\n\n', (passedTests / totalTests) * 100);

if allPassed
    fprintf('✓ All tests PASSED!\n\n');
else
    fprintf('✗ Some tests FAILED!\n\n');
end

%% 性能基准检查
fprintf('========================================\n');
fprintf('Performance Check (Sphere F1)\n');
fprintf('========================================\n\n');

if isfield(results.GWO.F1, 'bestFitness')
    fprintf('GWO:  %.6e (expected < 1e-5 for 100 iterations)\n', ...
        results.GWO.F1.bestFitness);
end

if isfield(results.ALO.F1, 'bestFitness')
    fprintf('ALO:  %.6e\n', results.ALO.F1.bestFitness);
end

if isfield(results.IGWO.F1, 'bestFitness')
    fprintf('IGWO: %.6e\n', results.IGWO.F1.bestFitness);
end

fprintf('\n');

%% 保存测试结果
fprintf('Saving test results...\n');
save('validation_results.mat', 'results');
fprintf('Results saved to: validation_results.mat\n\n');

fprintf('========================================\n');
fprintf('Validation test completed!\n');
fprintf('========================================\n');

%% 返回测试状态
if allPassed
    exit_code = 0;
else
    exit_code = 1;
end
