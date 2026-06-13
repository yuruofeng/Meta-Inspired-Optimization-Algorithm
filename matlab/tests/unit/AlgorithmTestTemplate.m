classdef AlgorithmTestTemplate < matlab.unittest.TestCase
    % AlgorithmTestTemplate 算法测试模板基类
    %
    % 提供通用的算法测试方法，子类只需指定算法名称即可

    properties (Abstract)
        AlgorithmClass  % 算法类句柄，如 @GWO
        AlgorithmName   % 算法名称，如 'GWO'
    end

    methods (Test)
        function testBasicOptimization(obj)
            rng(42, 'twister');
            
            config = struct('populationSize', 30, 'maxIterations', 100, 'verbose', false);
            algorithm = obj.AlgorithmClass(config);
            
            problem = struct();
            problem.evaluate = @(x) sum(x.^2);
            problem.lb = [-5 -5 -5 -5 -5];
            problem.ub = [5 5 5 5 5];
            problem.dim = 5;
            
            result = algorithm.run(problem);
            
            obj.assertEqual(class(result), 'OptimizationResult');
            obj.assertTrue(isfinite(result.bestFitness));
            obj.assertEqual(length(result.bestSolution), 5);
        end

        function testConvergence(obj)
            rng(42, 'twister');
            
            config = struct('populationSize', 30, 'maxIterations', 100, 'verbose', false);
            algorithm = obj.AlgorithmClass(config);
            
            problem = struct();
            problem.evaluate = @(x) sum(x.^2);
            problem.lb = [-10 * ones(1, 10)];
            problem.ub = [10 * ones(1, 10)];
            problem.dim = 10;
            
            result = algorithm.run(problem);
            
            obj.assertTrue(result.convergenceCurve(end) <= result.convergenceCurve(1));
        end

        function testDefaultConfig(obj)
            algorithm = obj.AlgorithmClass();
            
            obj.assertTrue(isfield(algorithm.config, 'populationSize'));
            obj.assertTrue(isfield(algorithm.config, 'maxIterations'));
            obj.assertTrue(algorithm.config.populationSize >= 10);
            obj.assertTrue(algorithm.config.maxIterations >= 1);
        end

        function testCustomConfig(obj)
            config = struct('populationSize', 50, 'maxIterations', 200, 'verbose', false);
            algorithm = obj.AlgorithmClass(config);
            
            obj.assertEqual(algorithm.config.populationSize, 50);
            obj.assertEqual(algorithm.config.maxIterations, 200);
        end

        function testBoundaryHandling(obj)
            rng(42, 'twister');
            
            config = struct('populationSize', 20, 'maxIterations', 50, 'verbose', false);
            algorithm = obj.AlgorithmClass(config);
            
            lb = [-100, -10, -1];
            ub = [100, 10, 1];
            problem = struct();
            problem.evaluate = @(x) sum(x.^2);
            problem.lb = lb;
            problem.ub = ub;
            problem.dim = 3;
            
            result = algorithm.run(problem);
            
            obj.assertTrue(all(result.bestSolution >= lb));
            obj.assertTrue(all(result.bestSolution <= ub));
        end

        function testSphereFunction(obj)
            rng(42, 'twister');
            
            config = struct('populationSize', 30, 'maxIterations', 100, 'verbose', false);
            algorithm = obj.AlgorithmClass(config);
            
            [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
            problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
            
            result = algorithm.run(problem);
            
            obj.assertTrue(result.bestFitness < 1);
        end

        function testInvalidProblem(obj)
            config = struct('populationSize', 30, 'maxIterations', 100, 'verbose', false);
            algorithm = obj.AlgorithmClass(config);
            
            try
                result = algorithm.run([]);
                obj.fail('Should have thrown an error for empty problem');
            catch ME
                obj.assertTrue(contains(ME.identifier, 'InvalidProblem'));
            end
        end

        function testInvalidBounds(obj)
            config = struct('populationSize', 30, 'maxIterations', 100, 'verbose', false);
            algorithm = obj.AlgorithmClass(config);
            
            problem = struct();
            problem.evaluate = @(x) sum(x.^2);
            problem.lb = [10, 10];
            problem.ub = [1, 1];
            problem.dim = 2;
            
            try
                result = algorithm.run(problem);
                obj.fail('Should have thrown an error for invalid bounds');
            catch ME
                obj.assertTrue(contains(ME.identifier, 'InvalidProblem'));
            end
        end
    end
end
