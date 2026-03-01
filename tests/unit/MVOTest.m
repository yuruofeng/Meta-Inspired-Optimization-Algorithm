classdef MVOTest < AlgorithmTestTemplate
    % MVOTest 多元宇宙优化算法单元测试

    properties
        AlgorithmClass = @MVO
        AlgorithmName = 'MVO'
    end

    methods (Test)
        function testWormholes(obj)
            rng(42, 'twister');
            
            config = struct('populationSize', 30, 'maxIterations', 50, 'verbose', false);
            mvo = MVO(config);
            
            problem = struct();
            problem.evaluate = @(x) sum(x.^2);
            problem.lb = [-5 -5 -5];
            problem.ub = [5 5 5];
            problem.dim = 3;
            
            result = mvo.run(problem);
            
            obj.assertTrue(isfinite(result.bestFitness));
        end

        function testRegistration(obj)
            MVO.register();
            algClass = AlgorithmRegistry.getAlgorithm('MVO');
            obj.assertEqual(algClass, @MVO);
        end
    end
end
