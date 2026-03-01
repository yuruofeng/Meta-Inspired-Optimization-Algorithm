classdef MFOTest < AlgorithmTestTemplate
    % MFOTest 飞蛾火焰优化算法单元测试

    properties
        AlgorithmClass = @MFO
        AlgorithmName = 'MFO'
    end

    methods (Test)
        function testFlameAdaptation(obj)
            rng(42, 'twister');
            
            config = struct('populationSize', 30, 'maxIterations', 50, 'verbose', false);
            mfo = MFO(config);
            
            problem = struct();
            problem.evaluate = @(x) sum(x.^2);
            problem.lb = [-5 -5 -5];
            problem.ub = [5 5 5];
            problem.dim = 3;
            
            result = mfo.run(problem);
            
            obj.assertTrue(isfinite(result.bestFitness));
        end

        function testRegistration(obj)
            MFO.register();
            algClass = AlgorithmRegistry.getAlgorithm('MFO');
            obj.assertEqual(algClass, @MFO);
        end
    end
end
