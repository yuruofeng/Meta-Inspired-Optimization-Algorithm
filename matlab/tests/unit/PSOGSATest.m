classdef PSOGSATest < matlab.unittest.TestCase
    % PSOGSATest 混合PSO-GSA算法的单元测试

    methods (Test)
        function testBasicOptimization(testCase)
            % 测试基本优化功能
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 30;
            config.maxIterations = 100;
            config.verbose = false;
            
            psogsa = PSOGSA(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = psogsa.run(problem);
            
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
            
            psogsa = PSOGSA(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = psogsa.run(problem);
            
            testCase.assertTrue(result.convergenceCurve(end) < result.convergenceCurve(1));
        end

        function testDefaultConfig(testCase)
            % 测试默认配置
            psogsa = PSOGSA();
            
            testCase.assertEqual(psogsa.config.populationSize, 30);
            testCase.assertEqual(psogsa.config.maxIterations, 500);
            testCase.assertEqual(psogsa.config.wMax, 0.9);
            testCase.assertEqual(psogsa.config.wMin, 0.5);
            testCase.assertEqual(psogsa.config.G0, 1);
            testCase.assertEqual(psogsa.config.alpha, 20);
            testCase.assertEqual(psogsa.config.c1, 0.5);
            testCase.assertEqual(psogsa.config.c2, 0.5);
            testCase.assertEqual(psogsa.config.verbose, true);
        end

        function testCustomConfig(testCase)
            % 测试自定义配置
            config = struct();
            config.populationSize = 50;
            config.maxIterations = 1000;
            config.wMax = 0.95;
            config.wMin = 0.4;
            config.G0 = 2;
            config.alpha = 15;
            config.c1 = 1;
            config.c2 = 1;
            config.verbose = false;
            
            psogsa = PSOGSA(config);
            
            testCase.assertEqual(psogsa.config.populationSize, 50);
            testCase.assertEqual(psogsa.config.maxIterations, 1000);
            testCase.assertEqual(psogsa.config.wMax, 0.95);
            testCase.assertEqual(psogsa.config.wMin, 0.4);
            testCase.assertEqual(psogsa.config.G0, 2);
            testCase.assertEqual(psogsa.config.alpha, 15);
            testCase.assertEqual(psogsa.config.verbose, false);
        end

        function testInvalidConfig(testCase)
            % 测试无效配置
            config = struct();
            config.populationSize = 5;
            
            try
                psogsa = PSOGSA(config);
                testCase.fail('Should have thrown an error for populationSize < 10');
            catch ME
                testCase.assertTrue(contains(ME.identifier, 'PSOGSA'));
            end
        end

        function testBoundaryHandling(testCase)
            % 测试边界处理
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 20;
            config.maxIterations = 50;
            config.verbose = false;
            
            psogsa = PSOGSA(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F2');
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = psogsa.run(problem);
            
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
            
            psogsa = PSOGSA(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F10');
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = psogsa.run(problem);
            
            testCase.assertEqual(length(result.bestSolution), dim);
            testCase.assertTrue(isfinite(result.bestFitness));
        end

        function testRegistration(testCase)
            % 测试算法注册
            PSOGSA.register();
            
            algClass = AlgorithmRegistry.getAlgorithm('PSOGSA');
            testCase.assertEqual(algClass, @PSOGSA);
        end

        function testVectorBounds(testCase)
            % 测试向量边界
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 20;
            config.maxIterations = 50;
            config.verbose = false;
            
            psogsa = PSOGSA(config);
            
            lb = [-100, -10, -1];
            ub = [100, 10, 1];
            dim = 3;
            fobj = @(x) sum(x.^2);
            
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = psogsa.run(problem);
            
            testCase.assertTrue(all(result.bestSolution >= lb));
            testCase.assertTrue(all(result.bestSolution <= ub));
        end

        function testHybridBehavior(testCase)
            % 测试混合行为
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 30;
            config.maxIterations = 100;
            config.verbose = false;
            
            psogsa = PSOGSA(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = psogsa.run(problem);
            
            testCase.assertTrue(result.bestFitness < 1);
        end
    end
end
