classdef RouletteWheelSelectionTest < matlab.unittest.TestCase
    % RouletteWheelSelectionTest 统一轮盘赌选择的单元测试

    methods (Test)
        function testBasicSelection(testCase)
            % 测试基本选择功能
            selector = shared.operators.selection.RouletteWheelSelection();
            weights = [10, 30, 20, 40];

            % 测试多次选择
            selections = zeros(1000, 1);
            for i = 1:1000
                idx = selector.selectOne(weights);
                testCase.assertTrue(idx >= 1 && idx <= 4);
                selections(i) = idx;
            end

            % 高权重应该被选中更多次
            testCase.assertTrue(sum(selections == 4) > sum(selections == 1));
        end

        function testNegativeWeights(testCase)
            % 测试负权重（MVO算法使用场景）
            selector = shared.operators.selection.RouletteWheelSelection();
            weights = [-10, -30, -20, -5];  % -5应该最可能被选中

            idx = selector.selectOne(weights);
            testCase.assertTrue(idx >= 1 && idx <= 4);
        end

        function testSelectMultiple(testCase)
            % 测试多次选择（GA风格）
            population = rand(50, 10);
            fitness = rand(50, 1);

            selector = shared.operators.selection.RouletteWheelSelection();
            indices = selector.select(population, fitness, 10);

            testCase.assertEqual(length(indices), 10);
            testCase.assertTrue(all(indices >= 1 & indices <= 50));
        end

        function testEdgeCases(testCase)
            % 测试边缘情况
            selector = shared.operators.selection.RouletteWheelSelection();

            % 单元素
            idx = selector.selectOne([1]);
            testCase.assertEqual(idx, 1);

            % 相等权重
            idx = selector.selectOne([1, 1, 1, 1]);
            testCase.assertTrue(idx >= 1 && idx <= 4);
        end

        function testBackwardCompatibility(testCase)
            % 测试函数式调用（向后兼容utils/版本）
            idx = shared.operators.selection.RouletteWheelSelection.quickSelect([10, 20, 30]);
            testCase.assertTrue(idx >= 1 && idx <= 3);
        end

        function testMinimizationProblem(testCase)
            % 测试最小化问题
            selector = shared.operators.selection.RouletteWheelSelection('problemType', 'minimization');
            fitness = [10, 5, 1, 8];  % 第3个应该最可能被选中

            selections = zeros(100, 1);
            for i = 1:100
                indices = selector.select(rand(4, 5), fitness, 1);
                selections(i) = indices(1);
            end

            % 适应度最低的应该被选中最多
            testCase.assertTrue(sum(selections == 3) > sum(selections == 1));
        end

        function testMaximizationProblem(testCase)
            % 测试最大化问题
            selector = shared.operators.selection.RouletteWheelSelection('problemType', 'maximization');
            fitness = [1, 5, 10, 3];  % 第3个应该最可能被选中

            selections = zeros(100, 1);
            for i = 1:100
                indices = selector.select(rand(4, 5), fitness, 1);
                selections(i) = indices(1);
            end

            % 适应度最高的应该被选中最多
            testCase.assertTrue(sum(selections == 3) > sum(selections == 1));
        end

        function testConstructorVariants(testCase)
            % 测试不同的构造方式
            % 默认构造
            selector1 = shared.operators.selection.RouletteWheelSelection();
            testCase.assertEqual(selector1.scalingFactor, 1);

            % 单参数构造
            selector2 = shared.operators.selection.RouletteWheelSelection(2);
            testCase.assertEqual(selector2.scalingFactor, 2);

            % 名称-值对构造
            selector3 = shared.operators.selection.RouletteWheelSelection('scalingFactor', 3, 'problemType', 'maximization');
            testCase.assertEqual(selector3.scalingFactor, 3);
            testCase.assertEqual(selector3.problemType, "maximization");
        end

        function testZeroAccumulation(testCase)
            % 测试累积和为0的情况
            selector = shared.operators.selection.RouletteWheelSelection();

            % 所有权重为0时应该随机选择
            idx = selector.selectOne([0, 0, 0, 0]);
            testCase.assertTrue(idx >= 1 && idx <= 4);
        end
    end
end
