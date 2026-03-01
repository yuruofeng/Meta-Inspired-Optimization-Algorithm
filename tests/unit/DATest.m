classdef DATest < AlgorithmTestTemplate
    % DATest 蜻蜓算法单元测试

    properties
        AlgorithmClass = @DA
        AlgorithmName = 'DA'
    end

    methods (Test)
        function testSwarmBehavior(obj)
            rng(42, 'twister');
            
            config = struct('populationSize', 30, 'maxIterations', 50, 'verbose', false);
            da = DA(config);
            
            problem = struct();
            problem.evaluate = @(x) sum(x.^2);
            problem.lb = [-5 -5 -5];
            problem.ub = [5 5 5];
            problem.dim = 3;
            
            result = da.run(problem);
            
            obj.assertTrue(isfinite(result.bestFitness));
        end

        function testRegistration(obj)
            DA.register();
            algClass = AlgorithmRegistry.getAlgorithm('DA');
            obj.assertEqual(algClass, @DA);
        end
    end
end
