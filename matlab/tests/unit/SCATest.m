classdef SCATest < matlab.unittest.TestCase
    % SCATest 正弦余弦算法的单元测试

    methods (Test)
        function testBasicOptimization(testCase)
            % 测试基本优化功能
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 30;
            config.maxIterations = 100;
            config.verbose = false;
            
            sca = SCA(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = sca.run(problem);
            
            testCase.assertEqual(class(result), 'OptimizationResult');
            testCase.assertTrue(isfinite(result.bestFitness));
            testCase.assertEqual(length(result.bestSolution), dim);
            testCase.assertEqual(length(result.convergenceCurve), config.maxIterations);
        end

        function testConvergence(testCase)
            % 测试算法收敛性
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 30;
            config.maxIterations = 200;
            config.verbose = false;
            
            sca = SCA(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = sca.run(problem);
            
            testCase.assertTrue(result.convergenceCurve(end) < result.convergenceCurve(1));
        end

        function testDefaultConfig(testCase)
            % 测试默认配置
            sca = SCA();
            
            testCase.assertEqual(sca.config.populationSize, 30);
            testCase.assertEqual(sca.config.maxIterations, 500);
            testCase.assertEqual(sca.config.a, 2);
            testCase.assertEqual(sca.config.verbose, true);
        end

        function testCustomConfig(testCase)
            % 测试自定义配置
            config = struct();
            config.populationSize = 50;
            config.maxIterations = 1000;
            config.a = 3;
            config.verbose = false;
            
            sca = SCA(config);
            
            testCase.assertEqual(sca.config.populationSize, 50);
            testCase.assertEqual(sca.config.maxIterations, 1000);
            testCase.assertEqual(sca.config.a, 3);
            testCase.assertEqual(sca.config.verbose, false);
        end

        function testInvalidConfig(testCase)
            % 测试无效配置
            config = struct();
            config.populationSize = 5;
            
            try
                sca = SCA(config);
                testCase.fail('Should have thrown an error for populationSize < 10');
            catch ME
                testCase.assertTrue(contains(ME.identifier, 'SCA'));
            end
        end

        function testBoundaryHandling(testCase)
            % 测试边界处理
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 20;
            config.maxIterations = 50;
            config.verbose = false;
            
            sca = SCA(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F2');
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = sca.run(problem);
            
            testCase.assertTrue(all(result.bestSolution >= lb));
            testCase.assertTrue(all(result.bestSolution <= ub));
        end

        function testMultiDimensional(testCase)
            % 测试高维问题
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 30;
            config.maxIterations = 100;
            config.verbose = false;
            
            sca = SCA(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F10');
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = sca.run(problem);
            
            testCase.assertEqual(length(result.bestSolution), dim);
            testCase.assertTrue(isfinite(result.bestFitness));
        end

        function testRegistration(testCase)
            % 测试算法注册
            SCA.register();
            
            algClass = AlgorithmRegistry.getAlgorithm('SCA');
            testCase.assertEqual(algClass, @SCA);
        end

        function testVectorBounds(testCase)
            % 测试向量边界
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 20;
            config.maxIterations = 50;
            config.verbose = false;
            
            sca = SCA(config);
            
            lb = [-100, -10, -1];
            ub = [100, 10, 1];
            dim = 3;
            fobj = @(x) sum(x.^2);
            
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = sca.run(problem);
            
            testCase.assertTrue(all(result.bestSolution >= lb));
            testCase.assertTrue(all(result.bestSolution <= ub));
        end
    end
end
