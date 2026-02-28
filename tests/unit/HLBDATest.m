classdef HLBDATest < matlab.unittest.TestCase
    % HLBDATest 超学习二进制蜻蜓算法的单元测试

    methods (Test)
        function testBasicOptimization(testCase)
            % 测试基本优化功能
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 10;
            config.maxIterations = 50;
            config.verbose = false;
            
            hlbda = HLBDA(config);
            
            dim = 20;
            fobj = @(x) sum(x.^2) + 0.1 * sum((1 - x).^2);
            
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            
            result = hlbda.run(problem);
            
            testCase.assertEqual(class(result), 'OptimizationResult');
            testCase.assertTrue(isfinite(result.bestFitness));
            testCase.assertEqual(length(result.bestSolution), dim);
            testCase.assertEqual(length(result.convergenceCurve), config.maxIterations);
        end

        function testConvergence(testCase)
            % 测试算法收敛性
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 10;
            config.maxIterations = 100;
            config.verbose = false;
            
            hlbda = HLBDA(config);
            
            dim = 20;
            fobj = @(x) sum(x.^2) + 0.1 * sum((1 - x).^2);
            
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            
            result = hlbda.run(problem);
            
            testCase.assertTrue(result.convergenceCurve(end) <= result.convergenceCurve(1));
        end

        function testDefaultConfig(testCase)
            % 测试默认配置
            hlbda = HLBDA();
            
            testCase.assertEqual(hlbda.config.populationSize, 10);
            testCase.assertEqual(hlbda.config.maxIterations, 100);
            testCase.assertEqual(hlbda.config.pp, 0.4);
            testCase.assertEqual(hlbda.config.pg, 0.7);
            testCase.assertEqual(hlbda.config.Dmax, 6);
            testCase.assertEqual(hlbda.config.verbose, true);
        end

        function testCustomConfig(testCase)
            % 测试自定义配置
            config = struct();
            config.populationSize = 20;
            config.maxIterations = 200;
            config.pp = 0.5;
            config.pg = 0.8;
            config.Dmax = 8;
            config.verbose = false;
            
            hlbda = HLBDA(config);
            
            testCase.assertEqual(hlbda.config.populationSize, 20);
            testCase.assertEqual(hlbda.config.maxIterations, 200);
            testCase.assertEqual(hlbda.config.pp, 0.5);
            testCase.assertEqual(hlbda.config.pg, 0.8);
            testCase.assertEqual(hlbda.config.Dmax, 8);
            testCase.assertEqual(hlbda.config.verbose, false);
        end

        function testInvalidConfig(testCase)
            % 测试无效配置
            config = struct();
            config.populationSize = 3;
            
            try
                hlbda = HLBDA(config);
                testCase.fail('Should have thrown an error for populationSize < 5');
            catch ME
                testCase.assertTrue(contains(ME.identifier, 'HLBDA'));
            end
        end

        function testBinarySolution(testCase)
            % 测试二进制解
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 10;
            config.maxIterations = 50;
            config.verbose = false;
            
            hlbda = HLBDA(config);
            
            dim = 20;
            fobj = @(x) sum(x.^2);
            
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            
            result = hlbda.run(problem);
            
            binaryValues = unique(result.bestSolution);
            for i = 1:length(binaryValues)
                testCase.assertTrue(binaryValues(i) == 0 || binaryValues(i) == 1);
            end
        end

        function testMultiDimensional(testCase)
            % 测试高维问题
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 15;
            config.maxIterations = 50;
            config.verbose = false;
            
            hlbda = HLBDA(config);
            
            dim = 50;
            fobj = @(x) sum(x.^2) + 0.1 * sum((1 - x).^2);
            
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            
            result = hlbda.run(problem);
            
            testCase.assertEqual(length(result.bestSolution), dim);
            testCase.assertTrue(isfinite(result.bestFitness));
        end

        function testRegistration(testCase)
            % 测试算法注册
            HLBDA.register();
            
            algClass = AlgorithmRegistry.getAlgorithm('HLBDA');
            testCase.assertEqual(algClass, @HLBDA);
        end

        function testFeatureSelection(testCase)
            % 测试特征选择场景
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 10;
            config.maxIterations = 30;
            config.verbose = false;
            
            hlbda = HLBDA(config);
            
            dim = 30;
            weights = rand(1, dim);
            fobj = @(x) sum(weights .* (1 - x).^2) + 0.01 * sum(x);
            
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            
            result = hlbda.run(problem);
            
            testCase.assertTrue(isfinite(result.bestFitness));
            testCase.assertTrue(all(result.bestSolution >= 0));
            testCase.assertTrue(all(result.bestSolution <= 1));
        end

        function testLearningProbabilities(testCase)
            % 测试学习概率配置
            rng(42, 'twister');
            
            config = struct();
            config.populationSize = 10;
            config.maxIterations = 50;
            config.pp = 0.3;
            config.pg = 0.6;
            config.verbose = false;
            
            hlbda = HLBDA(config);
            
            dim = 20;
            fobj = @(x) sum(x.^2);
            
            problem = struct();
            problem.evaluate = fobj;
            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            
            result = hlbda.run(problem);
            
            testCase.assertTrue(isfinite(result.bestFitness));
        end
    end
end
