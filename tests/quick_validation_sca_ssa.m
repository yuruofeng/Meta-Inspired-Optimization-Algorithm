%% SCA和SSA算法快速验证测试脚本
% 验证新整合的SCA和SSA算法是否能正常运行并产生合理结果
%
% 作者：RUOFENG YU
% 版本: 2.0.0
% 日期: 2026

clear; clc; close all;

fprintf('========================================\n');
fprintf('SCA & SSA Quick Validation Test\n');
fprintf('========================================\n\n');

%% 测试配置
testFunctions = {'F1', 'F9', 'F10'};  % Sphere, Rastrigin, Ackley
algorithms = {'SCA', 'SSA'};
populationSize = 30;
maxIterations = 100;

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
            rng(42, 'twister');

            [lb, ub, dim, fobj] = BenchmarkFunctions.get(funcName);

            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;

            config = struct();
            config.populationSize = populationSize;
            config.maxIterations = maxIterations;
            config.verbose = false;

            switch algName
                case 'SCA'
                    algorithm = SCA(config);
                case 'SSA'
                    algorithm = SSA(config);
            end

            tic;
            result = algorithm.run(problem);
            elapsedTime = toc;

            results.(algName).(funcName) = struct();
            results.(algName).(funcName).bestFitness = result.bestFitness;
            results.(algName).(funcName).totalEvaluations = result.totalEvaluations;
            results.(algName).(funcName).elapsedTime = elapsedTime;
            results.(algName).(funcName).converged = length(result.convergenceCurve) == maxIterations;

            passed = true;

            if ~isa(result, 'OptimizationResult')
                passed = false;
                fprintf('FAIL (wrong result type)\n');
            end

            if length(result.convergenceCurve) ~= maxIterations
                passed = false;
                fprintf('FAIL (wrong convergence curve length)\n');
            end

            expectedMinEvaluations = populationSize;
            if result.totalEvaluations < expectedMinEvaluations
                passed = false;
                fprintf('FAIL (too few evaluations)\n');
            end

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
    fprintf('All tests PASSED!\n\n');
else
    fprintf('Some tests FAILED!\n\n');
end

%% 测试算法注册
fprintf('========================================\n');
fprintf('Algorithm Registration Test\n');
fprintf('========================================\n\n');

try
    SCA.register();
    SSA.register();
    
    scaClass = AlgorithmRegistry.getAlgorithm('SCA');
    ssaClass = AlgorithmRegistry.getAlgorithm('SSA');
    
    if isa(scaClass, 'function_handle') && isa(ssaClass, 'function_handle')
        fprintf('Algorithm registration: PASSED\n\n');
    else
        fprintf('Algorithm registration: FAILED\n\n');
        allPassed = false;
    end
catch ME
    fprintf('Algorithm registration ERROR: %s\n\n', ME.message);
    allPassed = false;
end

%% 最终结果
fprintf('========================================\n');
fprintf('Final Result\n');
fprintf('========================================\n\n');

if allPassed
    fprintf('All validation tests PASSED!\n');
    fprintf('SCA and SSA algorithms have been successfully integrated.\n');
else
    fprintf('Some validation tests FAILED!\n');
    fprintf('Please review the errors above.\n');
end
