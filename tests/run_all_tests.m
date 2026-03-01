% run_all_tests 运行所有单元测试
%
% 此脚本运行tests/unit目录下的所有单元测试，并生成测试报告。
%
% 使用示例:
%   cd tests
%   run_all_tests
%
% 版本: 1.0.0
% 日期: 2026

fprintf('====================================\n');
fprintf('Running All Unit Tests\n');
fprintf('====================================\n\n');

% 记录开始时间
startTime = tic;

% 获取tests目录的路径
scriptPath = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptPath);

% 添加项目根目录和测试目录到路径
addpath(genpath(projectRoot));

% 运行测试
import matlab.unittest.TestSuite;

try
    % 使用绝对路径
    unitTestPath = fullfile(scriptPath, 'unit');
    suite = TestSuite.fromFolder(unitTestPath, 'IncludingSubfolders', true);
    runner = matlab.unittest.TestRunner.withTextOutput;

    results = runner.run(suite);

    % 计算耗时
    elapsedTime = toc(startTime);

    % 显示结果摘要
    fprintf('\n====================================\n');
    fprintf('Test Results Summary\n');
    fprintf('====================================\n');
    
    totalTests = length(results);
    passedTests = sum([results.Passed]);
    failedTests = sum([results.Failed]);
    
    fprintf('Total: %d\n', totalTests);
    fprintf('Passed: %d\n', passedTests);
    fprintf('Failed: %d\n', failedTests);
    fprintf('Elapsed Time: %.2f seconds\n', elapsedTime);

    if totalTests > 0
        passRate = (passedTests / totalTests) * 100;
        fprintf('Pass Rate: %.1f%%\n', passRate);
    end

    if failedTests == 0
        fprintf('\n✓ All tests passed!\n');
        exit_code = 0;
    else
        fprintf('\n✗ Some tests failed. Please review.\n');
        exit_code = 1;
    end

catch ME
    fprintf('\n====================================\n');
    fprintf('Test Execution Error\n');
    fprintf('====================================\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('Stack:\n');
    disp(ME.getReport);
    exit_code = 1;
end

fprintf('====================================\n');

% 返回退出码（用于CI/CD）
if exist('exit_code', 'var')
    exit(exit_code);
end
