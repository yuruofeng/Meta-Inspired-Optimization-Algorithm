classdef DemoTemplate < handle
    % DemoTemplate 演示脚本模板类
    %
    % 消除10+个demo文件中90%的重复代码，提供统一的演示框架。
    %
    % 使用示例:
    %   % 简单使用
    %   demo = DemoTemplate('GWO', struct('populationSize', 30), 'F1');
    %   result = demo.run();
    %
    %   % 自定义配置
    %   config = struct('populationSize', 50, 'maxIterations', 500, 'verbose', true);
    %   demo = DemoTemplate('GA', config, 'F5');
    %   result = demo.run();
    %
    % 版本: 1.0.0
    % 日期: 2026

    properties
        algorithmName string          % 算法名称
        functionName string = "F1"    % 测试函数名称
        config struct                 % 算法配置
        randomSeed integer = 42       % 随机种子
        verbose logical = true        % 是否显示详细信息
    end

    methods
        function obj = DemoTemplate(algorithmName, config, functionName)
            % DemoTemplate 构造函数
            %
            % 输入参数:
            %   algorithmName - 算法名称（如 'GWO', 'WOA', 'GA'）
            %   config - 算法配置结构体（可选）
            %   functionName - 测试函数名称（可选，默认 'F1'）

            if nargin < 1
                error('DemoTemplate:MissingParameter', ...
                    'algorithmName is required');
            end

            obj.algorithmName = algorithmName;

            if nargin >= 2 && ~isempty(config)
                obj.config = config;
            else
                obj.config = struct();
            end

            if nargin >= 3 && ~isempty(functionName)
                obj.functionName = functionName;
            end
        end

        function result = run(obj)
            % run 执行演示
            %
            % 输出参数:
            %   result - OptimizationResult 对象

            clc; close all;

            fprintf('========================================\n');
            fprintf('%s Demo\n', obj.algorithmName);
            fprintf('========================================\n\n');

            % 1. 设置随机种子
            rng(obj.randomSeed, 'twister');
            fprintf('Random seed: %d\n\n', obj.randomSeed);

            % 2. 获取测试函数
            [lb, ub, dim, fobj] = BenchmarkFunctions.get(obj.functionName);
            funcInfo = BenchmarkFunctions.getInfo(obj.functionName);
            obj.displayFunctionInfo(funcInfo, dim, lb, ub);

            % 3. 创建问题对象
            problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);

            % 4. 运行优化
            fprintf('Running %s optimization...\n\n', obj.algorithmName);
            tic;
            algorithm = AlgorithmRegistry.create(obj.algorithmName, obj.config);
            result = algorithm.run(problem);
            elapsedTime = toc;

            % 5. 显示结果
            fprintf('\n');
            result.display();
            fprintf('Optimization Time: %.3f seconds\n\n', elapsedTime);

            % 6. 绘制结果
            obj.plotResults(result, obj.functionName, funcInfo, dim, lb, ub);

            % 7. 验证精度
            obj.validatePrecision(result, obj.functionName);

            fprintf('\n========================================\n');
            fprintf('Demo completed successfully!\n');
            fprintf('========================================\n');
        end

        function displayFunctionInfo(obj, funcInfo, dim, lb, ub)
            % displayFunctionInfo 显示测试函数信息

            fprintf('Benchmark Function: %s\n', obj.functionName);
            fprintf('  Type: %s\n', funcInfo.type);
            fprintf('  Dimension: %d\n', dim);
            fprintf('  Bounds: [%.2f, %.2f]\n', lb, ub);
            fprintf('  Optimal Value: %.6e\n\n', funcInfo.optimalValue);
        end

        function plotResults(obj, result, funcName, funcInfo, dim, lb, ub)
            % plotResults 绘制结果图表

            figure('Position', [100, 100, 1200, 400]);

            % 子图1: 测试函数可视化（仅2D）
            subplot(1, 2, 1);
            if dim == 2
                obj.plotFunction2D(funcName, funcInfo, lb, ub);
            else
                text(0.5, 0.5, sprintf('Function dimension: %d', dim), ...
                    'HorizontalAlignment', 'center', 'FontSize', 12);
                axis off;
            end

            % 子图2: 收敛曲线
            subplot(1, 2, 2);
            result.plotConvergence('Title', sprintf('%s Convergence', obj.algorithmName));

            sgtitle(sprintf('%s Results - %s', obj.algorithmName, funcName), ...
                'FontSize', 14, 'FontWeight', 'bold');
        end

        function plotFunction2D(obj, funcName, funcInfo, lb, ub)
            % plotFunction2D 绘制2D测试函数

            % 创建网格
            x = linspace(lb, ub, 100);
            y = linspace(lb, ub, 100);
            [X, Y] = meshgrid(x, y);

            % 计算函数值
            Z = zeros(size(X));
            for i = 1:numel(X)
                Z(i) = funcInfo.handle([X(i), Y(i)]);
            end

            % 绘制等高线
            contourf(X, Y, Z, 50, 'LineColor', 'none');
            colorbar;
            xlabel('x_1');
            ylabel('x_2');
            title(sprintf('%s Function', funcName));
        end

        function validatePrecision(obj, result, funcName)
            % validatePrecision 验证优化精度

            % 根据不同测试函数设置阈值
            switch funcName
                case {'F1', 'F2', 'F3'}
                    threshold = 1e-10;
                case {'F4', 'F5'}
                    threshold = 1e-6;
                otherwise
                    threshold = 1e-5;
            end

            if result.bestFitness < threshold
                fprintf('✓ PASS: Achieved required precision (< %.2e)\n', threshold);
            else
                fprintf('⚠ WARNING: Did not achieve required precision\n');
                fprintf('  Current: %.6e, Target: %.2e\n', result.bestFitness, threshold);
            end
        end
    end

    methods (Static)
        function runSimple(algorithmName, config, functionName)
            % runSimple 静态方法，简化调用
            %
            % 使用示例:
            %   DemoTemplate.runSimple('GWO', struct('populationSize', 30), 'F1');

            demo = DemoTemplate(algorithmName, config, functionName);
            result = demo.run();
        end
    end
end
