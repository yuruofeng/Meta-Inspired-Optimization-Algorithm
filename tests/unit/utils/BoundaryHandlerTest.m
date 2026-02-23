classdef BoundaryHandlerTest < matlab.unittest.TestCase
    % BoundaryHandlerTest 边界处理工具的单元测试

    methods (Test)
        function testClipStrategyScalar(testCase)
            % 测试裁剪策略（标量边界）
            handler = shared.utils.BoundaryHandler('clip');

            % 测试向量
            positions = [-150, 0, 50, 120];
            lb = -100;
            ub = 100;
            result = handler.apply(positions, lb, ub);

            testCase.assertEqual(result(1), -100);  % 裁剪到下界
            testCase.assertEqual(result(2), 0);     % 在范围内
            testCase.assertEqual(result(3), 50);    % 在范围内
            testCase.assertEqual(result(4), 100);   % 裁剪到上界
        end

        function testClipStrategyMatrix(testCase)
            % 测试裁剪策略（矩阵输入）
            handler = shared.utils.BoundaryHandler('clip');
            positions = rand(30, 10) * 200 - 100;  % 可能超出边界
            lb = -100;
            ub = 100;
            result = handler.apply(positions, lb, ub);

            testCase.assertTrue(all(result(:) >= -100));
            testCase.assertTrue(all(result(:) <= 100));
        end

        function testClipStrategyVector(testCase)
            % 测试裁剪策略（向量边界）
            handler = shared.utils.BoundaryHandler('clip');
            positions = [150, -200, 50; 120, -150, 80];
            lb = [-100, -100, -100];
            ub = [100, 100, 100];
            result = handler.apply(positions, lb, ub);

            testCase.assertTrue(all(result(:) >= -100));
            testCase.assertTrue(all(result(:) <= 100));
        end

        function testStaticQuickClip(testCase)
            % 测试静态快速裁剪方法
            positions = [-150, 50, 120];
            result = shared.utils.BoundaryHandler.quickClip(positions, -100, 100);

            testCase.assertEqual(result(1), -100);
            testCase.assertEqual(result(2), 50);
            testCase.assertEqual(result(3), 100);
        end

        function testReflectStrategy(testCase)
            % 测试反射策略
            handler = shared.utils.BoundaryHandler('reflect');
            positions = 150;  % 超出上界100
            lb = -100;
            ub = 100;
            result = handler.apply(positions, lb, ub);

            % 150 -> 反射到 2*100 - 150 = 50
            testCase.assertEqual(result, 50);
        end

        function testRandomStrategy(testCase)
            % 测试随机重置策略
            handler = shared.utils.BoundaryHandler('random');
            positions = [150, -200, 50];
            lb = -100;
            ub = 100;
            result = handler.apply(positions, lb, ub);

            % 结果应该在边界内
            testCase.assertTrue(all(result >= -100 & result <= 100));
            % 第3个值在范围内应该不变
            testCase.assertEqual(result(3), 50);
        end

        function testMidpointStrategy(testCase)
            % 测试中点修复策略
            handler = shared.utils.BoundaryHandler('midpoint');
            positions = 150;
            currentPositions = 80;
            lb = -100;
            ub = 100;

            result = handler.apply(positions, lb, ub, currentPositions);

            % 150超出上界，修复到 (100 + 80) / 2 = 90
            testCase.assertEqual(result, 90);
        end

        function testEdgeCases(testCase)
            % 测试边缘情况
            handler = shared.utils.BoundaryHandler('clip');

            % 所有值都在边界内
            positions = [0, 50, -50];
            result = handler.apply(positions, -100, 100);
            testCase.assertEqual(result, positions);

            % 所有值都超出边界
            positions = [-150, 150];
            result = handler.apply(positions, -100, 100);
            testCase.assertEqual(result, [-100, 100]);
        end

        function testConstructor(testCase)
            % 测试构造函数
            handler1 = shared.utils.BoundaryHandler();
            testCase.assertEqual(handler1.strategy, "clip");

            handler2 = shared.utils.BoundaryHandler('reflect');
            testCase.assertEqual(handler2.strategy, "reflect");

            % 测试无效策略
            testCase.assertError(@() shared.utils.BoundaryHandler('invalid'), ...
                'BoundaryHandler:InvalidStrategy');
        end

        function testMatrixInputWithDifferentStrategies(testCase)
            % 测试矩阵输入在不同策略下的表现
            positions = rand(20, 15) * 300 - 150;
            lb = -100;
            ub = 100;

            strategies = {'clip', 'reflect', 'random'};
            for i = 1:length(strategies)
                handler = shared.utils.BoundaryHandler(strategies{i});
                result = handler.apply(positions, lb, ub);
                testCase.assertTrue(all(result(:) >= -100 & result(:) <= 100), ...
                    sprintf('Strategy %s failed', strategies{i}));
            end
        end
    end
end
