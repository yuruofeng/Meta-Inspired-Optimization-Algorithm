classdef GATest < AlgorithmTestTemplate
    % GATest 遗传算法单元测试

    properties
        AlgorithmClass = @GA
        AlgorithmName = 'GA'
    end

    methods (Test)
        function testCrossoverMutation(obj)
            rng(42, 'twister');
            
            config = struct('populationSize', 30, 'maxIterations', 50, 'verbose', false);
            ga = GA(config);
            
            problem = struct();
            problem.evaluate = @(x) sum(x.^2);
            problem.lb = [-5 -5 -5];
            problem.ub = [5 5 5];
            problem.dim = 3;
            
            result = ga.run(problem);
            
            obj.assertTrue(isfinite(result.bestFitness));
        end

        function testRegistration(obj)
            GA.register();
            algClass = AlgorithmRegistry.getAlgorithm('GA');
            obj.assertEqual(algClass, @GA);
        end
    end
end
