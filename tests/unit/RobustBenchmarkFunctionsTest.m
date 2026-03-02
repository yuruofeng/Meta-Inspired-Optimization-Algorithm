classdef RobustBenchmarkFunctionsTest < matlab.unittest.TestCase
    % RobustBenchmarkFunctionsTest 鲁棒基准函数测试类

    methods (Test)
        function testList(testCase)
            % 测试函数列表
            list = RobustBenchmarkFunctions.list();
            testCase.assertEqual(length(list), 8);
            testCase.assertEqual(list{1}, 'R1');
            testCase.assertEqual(list{8}, 'R8');
        end

        function testGetInfo(testCase)
            % 测试函数信息获取
            info = RobustBenchmarkFunctions.getInfo('R1');
            testCase.assertEqual(info.name, 'TP_Biased1');
            testCase.assertEqual(info.type, 'Biased');
            
            info = RobustBenchmarkFunctions.getInfo('R3');
            testCase.assertEqual(info.type, 'Deceptive');
            
            info = RobustBenchmarkFunctions.getInfo('R6');
            testCase.assertEqual(info.type, 'Multimodal');
            
            info = RobustBenchmarkFunctions.getInfo('R8');
            testCase.assertEqual(info.type, 'Flat');
        end

        function testGetTypes(testCase)
            % 测试类型列表
            types = RobustBenchmarkFunctions.getTypes();
            testCase.assertTrue(ismember('Biased', types));
            testCase.assertTrue(ismember('Deceptive', types));
            testCase.assertTrue(ismember('Multimodal', types));
            testCase.assertTrue(ismember('Flat', types));
        end

        function testGetByType(testCase)
            % 测试按类型获取函数
            biased = RobustBenchmarkFunctions.getByType('Biased');
            testCase.assertEqual(length(biased), 2);
            
            deceptive = RobustBenchmarkFunctions.getByType('Deceptive');
            testCase.assertEqual(length(deceptive), 3);
            
            multimodal = RobustBenchmarkFunctions.getByType('Multimodal');
            testCase.assertEqual(length(multimodal), 2);
            
            flat = RobustBenchmarkFunctions.getByType('Flat');
            testCase.assertEqual(length(flat), 1);
        end

        function testFunctionBounds(testCase)
            % 测试所有函数的边界设置
            for i = 1:8
                f = sprintf('R%d', i);
                [lb, ub, dim, ~, delta] = RobustBenchmarkFunctions.get(f);
                
                testCase.assertTrue(lb < ub);
                testCase.assertEqual(dim, 2);
                testCase.assertTrue(delta > 0);
            end
        end

        function testR1Biased1(testCase)
            % 测试R1函数
            [lb, ub, dim, fobj] = RobustBenchmarkFunctions.get('R1');
            
            testCase.assertEqual(lb, -100);
            testCase.assertEqual(ub, 100);
            testCase.assertEqual(dim, 2);
            
            x = [0, 0];
            fitness = fobj(x);
            testCase.assertTrue(isfinite(fitness));
        end

        function testR2Biased2(testCase)
            % 测试R2函数
            [lb, ub, ~, fobj] = RobustBenchmarkFunctions.get('R2');
            
            testCase.assertEqual(lb, -100);
            testCase.assertEqual(ub, 100);
            
            x = [0, 0];
            fitness = fobj(x);
            testCase.assertTrue(isfinite(fitness));
        end

        function testR3Deceptive1(testCase)
            % 测试R3函数
            [lb, ub, dim, fobj] = RobustBenchmarkFunctions.get('R3');
            
            testCase.assertEqual(lb, 0);
            testCase.assertEqual(ub, 1);
            
            x = [0.5, 0.5];
            fitness = fobj(x);
            testCase.assertTrue(isfinite(fitness));
        end

        function testR4Deceptive2(testCase)
            % 测试R4函数
            [~, ~, ~, fobj] = RobustBenchmarkFunctions.get('R4');
            
            x = [0.5, 0.5];
            fitness = fobj(x);
            testCase.assertTrue(isfinite(fitness));
        end

        function testR5Deceptive3(testCase)
            % 测试R5函数
            [lb, ub, dim, fobj] = RobustBenchmarkFunctions.get('R5');
            
            testCase.assertEqual(lb, 0);
            testCase.assertEqual(ub, 2);
            
            x = [1, 1];
            fitness = fobj(x);
            testCase.assertTrue(isfinite(fitness));
        end

        function testR6Multimodal1(testCase)
            % 测试R6函数
            [~, ~, ~, fobj] = RobustBenchmarkFunctions.get('R6');
            
            x = [0.5, 0.5];
            fitness = fobj(x);
            testCase.assertTrue(isfinite(fitness));
        end

        function testR7Multimodal2(testCase)
            % 测试R7函数
            [~, ~, ~, fobj] = RobustBenchmarkFunctions.get('R7');
            
            x = [0.5, 0.5];
            fitness = fobj(x);
            testCase.assertTrue(isfinite(fitness));
        end

        function testR8Flat(testCase)
            % 测试R8函数
            [~, ~, ~, fobj] = RobustBenchmarkFunctions.get('R8');
            
            x = [0.5, 0.5];
            fitness = fobj(x);
            testCase.assertTrue(isfinite(fitness));
        end

        function testInvalidFunction(testCase)
            % 测试无效函数名称
            try
                RobustBenchmarkFunctions.get('R9');
                testCase.fail('Should have thrown an error');
            catch ME
                testCase.assertTrue(contains(ME.identifier, 'UnknownFunction'));
            end
        end

        function testAlgorithmIntegration(testCase)
            % 测试与算法的集成
            rng(42, 'twister');
            
            [lb, ub, dim, fobj] = RobustBenchmarkFunctions.get('R3');
            
            config = struct('populationSize', 30, 'maxIterations', 50, 'verbose', false);
            gwo = GWO(config);
            
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb * ones(1, dim);
            problem.ub = ub * ones(1, dim);
            problem.dim = dim;
            
            result = gwo.run(problem);
            
            testCase.assertEqual(class(result), 'OptimizationResult');
            testCase.assertTrue(isfinite(result.bestFitness));
            testCase.assertEqual(length(result.bestSolution), dim);
        end
    end
end
