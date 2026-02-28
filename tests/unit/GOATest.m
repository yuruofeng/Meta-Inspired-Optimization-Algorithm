classdef GOATest < matlab.unittest.TestCase
    % GOATest 蚱蜢优化算法的单元测试

    methods (Test)
        function testBasicOptimization(testCase)
            % 测试基本优化功能
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 30;
            config.maxIterations = 100;
            config.verbose = false;
            
            goa = GOA(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = goa.run(problem);
            
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
            
            goa = GOA(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = goa.run(problem);
            
            testCase.assertTrue(result.convergenceCurve(end) < result.convergenceCurve(1));
        end

        function testDefaultConfig(testCase)
            % 测试默认配置
            goa = GOA();
            
            testCase.assertEqual(goa.config.populationSize, 30);
            testCase.assertEqual(goa.config.maxIterations, 500);
            testCase.assertEqual(goa.config.cMax, 1);
            testCase.assertEqual(goa.config.cMin, 0.00004);
            testCase.assertEqual(goa.config.f, 0.5);
            testCase.assertEqual(goa.config.l, 1.5);
            testCase.assertEqual(goa.config.verbose, true);
        end

        function testCustomConfig(testCase)
            % 测试自定义配置
            config = struct();
            config.populationSize = 50;
            config.maxIterations = 1000;
            config.cMax = 2;
            config.cMin = 0.0001;
            config.verbose = false;
            
            goa = GOA(config);
            
            testCase.assertEqual(goa.config.populationSize, 50);
            testCase.assertEqual(goa.config.maxIterations, 1000);
            testCase.assertEqual(goa.config.cMax, 2);
            testCase.assertEqual(goa.config.cMin, 0.0001);
            testCase.assertEqual(goa.config.verbose, false);
        end

        function testInvalidConfig(testCase)
            % 测试无效配置
            config = struct();
            config.populationSize = 5;
            
            try
                goa = GOA(config);
                testCase.fail('Should have thrown an error for populationSize < 10');
            catch ME
                testCase.assertTrue(contains(ME.identifier, 'GOA'));
            end
        end

        function testBoundaryHandling(testCase)
            % 测试边界处理
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 20;
            config.maxIterations = 50;
            config.verbose = false;
            
            goa = GOA(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F2');
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = goa.run(problem);
            
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
            
            goa = GOA(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F10');
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = goa.run(problem);
            
            testCase.assertEqual(length(result.bestSolution), dim);
            testCase.assertTrue(isfinite(result.bestFitness));
        end

        function testRegistration(testCase)
            % 测试算法注册
            GOA.register();
            
            algClass = AlgorithmRegistry.getAlgorithm('GOA');
            testCase.assertEqual(algClass, @GOA);
        end

        function testSFunc(testCase)
            % 测试社会力函数
            goa = GOA();
            
            s1 = goa.s_func(0);
            testCase.assertTrue(s1 < 0);
            
            s2 = goa.s_func(2);
            testCase.assertTrue(abs(s2) < 1);
            
            s3 = goa.s_func(10);
            testCase.assertTrue(abs(s3) < 0.01);
        end

        function testVectorBounds(testCase)
            % 测试向量边界
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 20;
            config.maxIterations = 50;
            config.verbose = false;
            
            goa = GOA(config);
            
            lb = [-100, -10, -1];
            ub = [100, 10, 1];
            dim = 3;
            fobj = @(x) sum(x.^2);
            
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = dim;
            
            result = goa.run(problem);
            
            testCase.assertTrue(all(result.bestSolution >= lb));
            testCase.assertTrue(all(result.bestSolution <= ub));
        end
    end
end
