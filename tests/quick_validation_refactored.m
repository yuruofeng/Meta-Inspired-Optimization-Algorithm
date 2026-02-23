%% 快速验证脚本（带路径设置）
% 验证重构后的代码是否正常工作
%
% 版本: 1.0.0
% 日期: 2026

% 获取脚本所在目录
scriptPath = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptPath);

% 添加所有必要的目录到MATLAB路径
addpath(genpath(projectRoot));

fprintf('Project root: %s\n', projectRoot);
fprintf('Adding paths...\n\n');

fprintf('========================================\n');
fprintf('Quick Validation Script\n');
fprintf('========================================\n\n');

successCount = 0;
totalCount = 0;

%% 1. 测试共享算子
fprintf('1. Testing Shared Operators...\n');
totalCount = totalCount + 3;

% 测试RouletteWheelSelection
try
    selector = shared.operators.selection.RouletteWheelSelection();
    idx = selector.selectOne([10, 20, 30, 40]);
    fprintf('   ✓ RouletteWheelSelection works (selected: %d)\n', idx);
    successCount = successCount + 1;
catch ME
    fprintf('   ✗ RouletteWheelSelection failed: %s\n', ME.message);
end

% 测试TournamentSelection
try
    selector = shared.operators.selection.TournamentSelection('mode', 'kway', 'tournamentSize', 3);
    pop = rand(10, 5);
    fitness = rand(10, 1);
    indices = selector.select(pop, fitness, 3);
    fprintf('   ✓ TournamentSelection works (selected %d individuals)\n', length(indices));
    successCount = successCount + 1;
catch ME
    fprintf('   ✗ TournamentSelection failed: %s\n', ME.message);
end

% 测试UniformCrossover
try
    crossover = shared.operators.crossover.UniformCrossover(0.5);
    parent1 = rand(1, 10);
    parent2 = rand(1, 10);
    [child1, child2] = crossover.cross(parent1, parent2);
    fprintf('   ✓ UniformCrossover works\n');
    successCount = successCount + 1;
catch ME
    fprintf('   ✗ UniformCrossover failed: %s\n', ME.message);
end

%% 2. 测试BoundaryHandler
fprintf('\n2. Testing BoundaryHandler...\n');
totalCount = totalCount + 1;

try
    positions = [-150, 50, 120, -200];
    lb = -100;
    ub = 100;
    result = shared.utils.BoundaryHandler.quickClip(positions, lb, ub);
    expected = [-100, 50, 100, -100];
    if isequal(result, expected)
        fprintf('   ✓ BoundaryHandler.quickClip works correctly\n');
        successCount = successCount + 1;
    else
        fprintf('   ✗ BoundaryHandler.quickClip produced unexpected result\n');
        fprintf('     Expected: [%s]\n', num2str(expected));
        fprintf('     Got:      [%s]\n', num2str(result));
    end
catch ME
    fprintf('   ✗ BoundaryHandler failed: %s\n', ME.message);
end

%% 3. 测试向后兼容性
fprintf('\n3. Testing Backward Compatibility...\n');
totalCount = totalCount + 1;

try
    % 测试utils/RouletteWheelSelection包装器
    idx = RouletteWheelSelection([10, 20, 30]);
    fprintf('   ✓ Backward compatible RouletteWheelSelection works (selected: %d)\n', idx);
    successCount = successCount + 1;
catch ME
    fprintf('   ✗ Backward compatibility failed: %s\n', ME.message);
end

%% 4. 测试算法运行
fprintf('\n4. Testing Algorithm Execution...\n');
totalCount = totalCount + 1;

try
    % 使用GWO进行简单测试
    config = struct('populationSize', 10, 'maxIterations', 50, 'verbose', false);
    algorithm = AlgorithmRegistry.create('GWO', config);

    [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);

    result = algorithm.run(problem);

    fprintf('   ✓ GWO runs successfully\n');
    fprintf('     Best fitness: %.6e\n', result.bestFitness);
    fprintf('     Iterations: %d\n', result.metadata.iterations);
    successCount = successCount + 1;
catch ME
    fprintf('   ✗ Algorithm execution failed: %s\n', ME.message);
    % 打印堆栈信息以便调试
    % disp(ME.getReport);
end

%% 5. 测试DemoTemplate
fprintf('\n5. Testing DemoTemplate...\n');
totalCount = totalCount + 1;

try
    config = struct('populationSize', 10, 'maxIterations', 20, 'verbose', false);
    % 注意：DemoTemplate.run()会创建图形窗口，这里只测试构造
    demo = shared.templates.DemoTemplate('GWO', config, 'F1');
    fprintf('   ✓ DemoTemplate instantiation works\n');
    successCount = successCount + 1;
catch ME
    fprintf('   ✗ DemoTemplate failed: %s\n', ME.message);
end

%% 最终统计
fprintf('\n========================================\n');
fprintf('Validation Summary\n');
fprintf('========================================\n');
fprintf('Tests Passed: %d/%d (%.1f%%)\n', successCount, totalCount, ...
    (successCount/totalCount)*100);

if successCount == totalCount
    fprintf('\n✓ ALL TESTS PASSED!\n');
    exit_code = 0;
else
    fprintf('\n✗ SOME TESTS FAILED\n');
    exit_code = 1;
end
fprintf('========================================\n');
